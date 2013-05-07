library(cluster)
library(rjson)

setwd("~/Downloads/github")
orig.data <- read.csv("output/last-year-monthly.csv", header=T)
# orig.data <- orig.data[!orig.data$language %in% c("JavaScript", "Ruby", "PHP", "Python", "Java", "C", "C++"),]

prune.data <- function(events) {
  events.data <- events[,3:20]
  drop.names <- which(colSums(events.data) == 0)
  pruned.events.data <- events.data[,-drop.names]
}

plot.wss <- function(data, maxclusters=10, main="") {
  wss = (nrow(data)-1)*sum(apply(data,2,var))
  for (i in 2:maxclusters) wss[i] <- kmeans(data, centers=i)$tot.withinss
  plot(1:maxclusters, wss, type="b", xlab="Number of Clusters",
       ylab="Within groups sum of squares", main=main)  
}

vector.length <- function(v) {
  sqrt(sum(v^2))
}

find.pca <- function(events, langs) {
  events.pca <- princomp(events, cor=TRUE, scores=T)
  comp.events <- cbind(events.pca$scores[,1], events.pca$scores[,2])
  rownames(comp.events) <- langs
  comp.events
}

svg("output/cluster.svg", width=12, height=7)
par(mfrow=c(3,4), mar=c(4,4,3,1), cex.lab=1)

clusters <- c(5,5,3,4,4,4,4,5,5,6,5,6) # chosen by examining wss plot
i <- 1
output <- list()
for (month in c("201205", "201206", "201207", "201208", "201209", "201210", "201211", "201212", "201301", "201302", "201303", "201304")) {
  print(month)
  events <- orig.data[orig.data$time==month,]
  pruned.events.data <- prune.data(events)
  comp.events <- find.pca(pruned.events.data, events$language)
  
  ## plot.wss(pruned.events.data, main=month)
  
  kclust <- kmeans(comp.events, centers=clusters[i], nstart=100)  
  clusplot(comp.events, kclust$cluster, color=TRUE, shade=TRUE, labels=2, lines=0, cex=0.8, main=paste(month, " (", "cluster number: ", clusters[i], ")", sep=""))

  langLength<-apply(pruned.events.data, 1, vector.length)
  langNames <- as.character(events$language)
  langs.length <- data.frame(language=langNames, length=langLength)
  ## if (month == "201302") {
  ##   print(events[events$language=='Nemerle',])
  ##   print(langs.length[order(langs.length$length),], decreasing=T)
  ## }
    
  cluster.mean.length <- function(langs) {
    langsLength <- langs.length$length[langs.length$language %in% langs]
    max(langsLength)
  }
  
  cluster <- kclust$cluster
  clusterGroups <- split(names(cluster), cluster)
  clusterMeans <- lapply(clusterGroups, cluster.mean.length)
  
  orderedClusterGroups <- clusterGroups[order(simplify2array(clusterMeans), decreasing=T)]
  orderedClusterGroups <- lapply(orderedClusterGroups, function(group) {
    group[order(langs.length$length[langs.length$language %in% group], decreasing=T)]
  })
  names(orderedClusterGroups) <- seq(1, length(orderedClusterGroups))
  output[[month]] <- orderedClusterGroups
  
  i = i + 1
}

dev.off();

f<-file("output/clusters.json", "w+")
writeLines(toJSON(output), f)
close(f)

