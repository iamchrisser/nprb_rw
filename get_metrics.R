

gql_results <- list.files("results/", pattern = "*.csv")

get_project_volumes <- function(project_files){
  project_size <- data.frame(p.id=numeric(), p.name=character(), p.volume=numeric()) 
  names(project_size)=c("project_id","project_name","project_bytes")
  
  for (i in gql_results){
    file_name <- paste("results/",i,sep="")
    print(paste("working with file: ", file_name))
    df <- read_csv(file_name)
    df <- aggregate(df$bytes, by=list(df$p.id, df$p.name), FUN=sum)
    names(df) <- names(project_size)
    project_size <- rbind(project_size, df)
  }
  
  project_MB <- project_size["project_bytes"] / 1024^2
  names(project_MB) <- "project_MB"
  project_size <- cbind(project_size, project_MB)
  return(project_size)
}

ps <- get_project_volumes(gql_results)

min(project_size$project_volume)


sum(project_size$project_volume)