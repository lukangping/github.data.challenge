setwd("~/Downloads/github")
orig.data <- read.csv("output/last-year-monthly.csv", header=T)

# unique.time <- unique(orig.data$time)
# levels(orig.data$time) <- unique.time[order(strftime(as.POSIXct(unique.time, "%Y-%m-%d-%H", tz="UTC"), "%s"))]
# orig.data$timestamp <- strftime(as.POSIXct(orig.data$time, "%Y-%m-%d-%H", tz="UTC"), "%s")

par(mfrow=c(1,1))
lang.plot <- function(data, lang, col, lang.color=rgb(0,0,0,0.5), plot.func=plot) {
  lang.data <- data[data$language == lang,]
  plot.func(lang.data[,c("time")], lang.data[,c(col)], col=lang.color, pch=19, cex=0.8, xlab="time", ylab=col)
}

par(mfrow=c(3,2))
for (col in c("PushEvent", "CreateEvent", "WatchEvent", "IssuesEvent", "ForkEvent", "PullRequestEvent")) {
  lang.plot(orig.data, "JavaScript", col, lang.color=rgb(1,0,0,0.5))
  lang.plot(orig.data, "Ruby", col, lang.color=rgb(0,1,0,0.5), plot.func=points)
  lang.plot(orig.data, "Java", col, lang.color=rgb(0,0,1,0.5), plot.func=points)  
}


par(mfrow=c(2,3))

prune.data <- function(events) {
  events.data <- events[,3:20]
  drop.names <- which(colSums(events.data) == 0)
  pruned.events.data <- events.data[,-drop.names]
}

lang.pca.plot <- function(events) {
  source("myplclust.R") 
  langs <- as.numeric(as.factor(events$language))

  pruned.events.data <- prune.data(events)
  
  events.pca <- princomp(pruned.events.data, cor=TRUE, scores=T)
  screeplot(events.pca, type="lines")
  comp.events <- scale(as.matrix(pruned.events.data)) %*% as.matrix(events.pca$loadings[,1:2])
  
  distanceMatrix <- dist(comp.events) 
  hclustering <- hclust(distanceMatrix) 
  myplclust(hclustering,lab.col=langs)
  
  # svd1 <- svd(scale(pruned.events.data))
  # plot(svd1$d,xlab="Column",ylab="Singluar value",pch=19) 
  # plot(svd1$d^2/sum(svd1$d^2),xlab="Column",ylab="Percent of variance explained",pch=19)
  
  
  #library(RColorBrewer)
  #events.lang.colors <- colorRampPalette(brewer.pal(11, "Spectral"))(nrow(events))
  events.lang.colors <- colors()[seq(1,nrow(events))]
  plot(comp.events, pch=19, cex=0.8, col=events.lang.colors)
  #legend(-13,6,legend=events$language,col=events.lang.colors,pch=19, cex=0.5)
  text(comp.events + c(0.3,-0.3), labels=events$language, cex=0.8)
}

events <- orig.data[orig.data$time=="201204",]
lang.pca.plot(events)
events <- orig.data[orig.data$time=="201304",]
lang.pca.plot(events)


lang.pca <- function(events) {
  events.data <- events[,3:20]
  drop.names <- which(colSums(events.data) == 0)
  pruned.events.data <- events.data[,-drop.names]

  events.pca <- princomp(pruned.events.data, cor=TRUE, scores=T)
  comp.events <- scale(as.matrix(pruned.events.data)) %*% as.matrix(events.pca$loadings[,1:2])
  comp.events <- as.data.frame(comp.events)
  comp.events$language <- events[,c("language")]
  comp.events
}

comp.list <- data.frame(row.names=c("Comp.1", "Comp.2", "language", "time"))
for (day in seq(1, 30)) {
  day.str <- paste0("2012-04-", sprintf("%02s", day), "-15")
  events <- orig.data[orig.data$time=="2012-04-30-2",]
  lpca <- lang.pca(events)
  lpca$time <- rep(day.str, nrow(events))
  comp.list <- rbind(comp.list, lpca)  
}





