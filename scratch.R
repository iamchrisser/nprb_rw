

temp_var <-list(projectId = 268987)
result <- fromJSON(conn$exec(all_proj$link, variables = temp_var), flatten = F)

what_df <- test %>% 
  toJSON() %>%
  fromJSON() %>%
  purrr::flatten() %>%
  map_if(is_list, as_tibble) %>%
  map_if(is_tibble, list) %>%
  bind_cols() 


rgx_split <- "\\."
n_cols_max <-
  what_df %>%
  pull(name) %>% 
  str_split(rgx_split) %>% 
  map_dbl(~length(.)) %>% 
  max()
n_cols_max

nms_sep <- paste0("name", 1:n_cols_max)
data_sep <-
  what_df %>% 
  separate(name, into = nms_sep, sep = rgx_split, fill = "right")
data_sep

#test <- get_all_projects(unlist(df_02$id))
good_names <- c("proj.id", "proj.name", "folder.id", "folder.name", "folder.path")
annual_df <- data.frame(matrix(ncol = length(good_names), nrow = 0))
colnames(annual_df) <- good_names

for (i in 1:length(test)){
  test_df <- test[1]$data$project$folders$nodes
  p.name <- rep(test[1]$data$project$name, 23)
  p.id <- rep(test[1]$data$project$id, 23)
  test_df <- cbind(p.id, p.name, test_df)
  annual_df <- rbind(annual_df, test_df)
}
write_csc()


--------------
  # get_project_info <- function(list_of_ids){
  # #  project_info <- list()
  #   for (i in 1:length(list_of_ids)){
  #     temp_var <-list(projectId = list_of_ids[i])
  #     print(paste("Querying for project: ", list_of_ids[i], sep=""))
  #     result <- fromJSON(conn$exec(all_proj$link, variables = temp_var), flatten = F)
  # #    project_info <- append(project_info, result)
  #     }
  # #  return(project_info)
  # }
  
  ## rewrite this to get individual project info, reformat, write to file, clear memory, and then move on to the next project
ids <- unlist(project_df$id)

proj_results_df <- data.frame(matrix(ncol = length(good_names), nrow = 0))
colnames(all_proj_df) <- good_names

all_projects <- get_project_info(ids)

for (i in 1:length(all_projects)){
  project_df <- all_projects[i]$data$project$folders$nodes
  p.name <- rep(all_projects[i]$data$project$name, nrow(project_df))
  p.id <- rep(all_projects[i]$data$project$id, nrow(project_df))
  project_df <- cbind(p.id, p.name, project_df)
  all_proj_df <- rbind(all_proj_df, project_df)
}

write.csv(all_proj_df, "results/nprb_all_projects.csv")

# annual_results <- function(list_of_years){
#   for (y in project_years){
#     this_year <- paste0("20", y)
#     df_y <- project_df[startsWith(project_df$name, y),]
#     ids <- unlist(df_y$id)
#     print(paste("Sending GQL query for year: 20", y, sep=""))
#     annual_projects <- get_project_info(ids)
#     
#     annual_df <- data.frame(matrix(ncol = length(good_names), nrow = 0))
#     colnames(annual_df) <- good_names
#     
#     for (i in 1:length(annual_projects)){
#       project_df <- annual_projects[i]$data$project$folders$nodes
#       p.name <- rep(annual_projects[i]$data$project$name, nrow(project_df))
#       p.id <- rep(annual_projects[i]$data$project$id, nrow(project_df))
#       project_df <- cbind(p.id, p.name, project_df)
#       annual_df <- rbind(annual_df, project_df)
#     }
#     outfile <- paste("results/nprb_projects_", this_year,".csv", sep="")
#     write_csv(all_project_df, "results/nprb_all_projects.csv")
#     print(paste("Done with 20", y,".", sep=""))
#   }
#   #return(annual_df)
#   #print("Done.")
# }

#all_project_df <- annual_results(project_years)

for (i in project_ids){
  get_project_info(i) %>%
    clean_project_info() %>%
    write.csv(outfile, append = TRUE, row.names = FALSE)
}
