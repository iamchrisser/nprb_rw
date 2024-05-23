needs <- c("ghql", "jsonlite", "dplyr", "stringr", "readr")

# Install packages not yet installed
installed_packages <- needs %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(needs[!installed_packages])
}

# Packages loading
invisible(lapply(needs, library, character.only = TRUE))

# read in csvs already downloaded from RW admin
# I'm using all of the results on each page of results
# from the admin page below, concatenated into a single csv with the following:
# csvstack * > nprb_all_projects.csv
# https://admin.researchworkspace.com/organization/id/2561283/projects/search?c=project[id,name,isArchived,isPublic,fileCount]&pageSize=100

project_df <- read_csv("./nprb_all-projects/nprb_all_projects.csv")
names(project_df) = c("id", "name", "archived", "public", "files")
project_df[project_df == "[object Object]"] <- "1"
project_df[project_df == "—"] <- NA
project_df <- transform(project_df, archived = as.integer(archived), public = as.integer(public), files = as.integer(files))
project_df <- transform(project_df, archived = as.logical(archived), public = as.logical(public))

project_years <- c("14", "15", "16", "17", "18", "19", "20", "21", "22", "23")
#project_years <- c("02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23")
project_ids <- unlist(project_df$id)
good_names <- c("proj.id", "proj.name", "folder.id", "folder.name", "folder.path")

# defining some queries
# first, we'll ask for the count of files for the given archivePackageId
query_all_proj <- '
query Campaign($projectId: Float!) {
  project(id: $projectId) {
    id
    name
    folders {
      nodes {
        name
        id
        bytes
        path
      }
    }
  }
}'

# setting up the connection to the graphql endpoint
link <- 'https://gql.researchworkspace.com/graphql'
conn <- GraphqlClient$new(url = link)
all_proj <- Query$new()$query('link', query_all_proj)

# given a project ID, query the GQL endpoint for project info, return result
get_project_info <- function(project_id){
  temp_var <-list(projectId = project_id)
  print(paste("Querying for project: ", project_id, sep=""))
  result <- fromJSON(conn$exec(all_proj$link, variables = temp_var), flatten = F)
  return(result)
}

clean_project_info <- function(gql_result){
  project_df <- gql_result$data$project$folders$nodes
  p.name <- rep(gql_result$data$project$name, nrow(project_df))
  p.id <- rep(gql_result$data$project$id, nrow(project_df))
  project_df <- cbind(p.id, p.name, project_df)
}

for (y in project_years){
  print(paste("working on year: ", y, sep=""))
  
  proj_results_df <- data.frame(matrix(ncol = length(good_names), nrow = 0))
  colnames(proj_results_df) <- good_names
  
  ids <- unlist(project_df[startsWith(project_df$name, y),]$id)
  
  for (i in ids){
    p <- get_project_info(i)
    c <-  clean_project_info(p)
    proj_results_df <- rbind(proj_results_df, c)
  }
  
  print(paste("writing results for year: ", y, sep=""))
  outfile <- paste("results/nprb_projects_", y, "_", as.character(Sys.Date()),".csv", sep="")
  write.csv(proj_results_df, outfile, row.names = FALSE)
  print("Done.")
}