
###############################################################################
##FUNCTIONS TO CALCULATE THE MONEY WEIGHTED MEANS
###############################################################################
get.contrib.means <- function(cm,cand.ips,contrib.ips=NULL,weights=NULL,upper.limit=2000,
                              get.sds=FALSE,cores=1){
    numconts <- nrow(cm)
    use.weights <- !is.null(weights)
    use <- !is.na(as.numeric(cand.ips))
    t1 <- cm[,use] %*% (as.numeric(cand.ips[use]))
    t2 <- rowSums(cm[,use])
    contrib.ips <- as.numeric(t1/t2)
    return(contrib.ips)
}


get.cand.means <- function(cm,contrib.ips,weights=NULL,dynamic.cands=FALSE,
                           upper.limit=30,cores=1,get.sds=F){
  numconts <- ncol(cm)
  cm <- cm[!is.na(contrib.ips),]
  contrib.ips <- contrib.ips[!is.na(contrib.ips)]
  count <- 1

  cand.ips <- rep(NA,numconts)
  t1 <- t(cm) %*% (as.numeric(contrib.ips))
  t2 <- colSums(cm)
  cand.ips <- as.numeric(t1/t2)
  
  return(cand.ips)
}


normalize.rows <- function(x,y){
  y <- y/ sum(y)
  ##CENTERING
  ctr <- as.numeric(t(y) %*% x)
  x <- x - as.numeric(ctr)
  ##SCALING VARIANCE = 1
  vtr <-  t(x) %*% Diagonal(length(y),y) %*% x
  x <- x * (1/sqrt(as.numeric(vtr)))
  return(x)
}

normalize.cols <- function(x,y){
  y <- y/ sum(y)
  ##CENTERING
  ctr <- as.numeric(t(y) %*% x)
  x <- x - as.numeric(ctr)
  ##SCALING VARIANCE = 1
  vtr <-  t(x) %*% Diagonal(length(y),y) %*% x
  scale.param <- (1/sqrt(as.numeric(vtr)))
  x <- x * scale.param
  return(list(x=x,scale.param=scale.param))
}


awm <- function(cands=NA, cm=NA,iters = 8){

    cat('\n Correspondence Analysis: \n')
    print(table(cands[,'party']))
    cands[cands[,'party'] %in% c('D','DEM','Dem'),'party'] <- 100
    cands[cands[,'party'] %in% c('R','REP','Rep'),'party'] <- 200
    cands[!(cands[,'party'] %in% c(100,200)),'party'] <- 328

    ##RESTRICTING cands TO FEDERAL CANDIDATES
    use.fed <- grepl('fed',cands[,'seat'])
    cands <- cands[use.fed,]
    ##EXTRACTING CANDIDATE IDS
    icpsr = (cands[,'ICPSR'])
    icpsr2 <- (cands[,'ICPSR2'])
    mm <- !duplicated(icpsr2)
    cands <- cands[mm,]
    ##RESTRICTING CONTRIB.MATRIX TO FEDERAL CANDIDATES
    contrib.ips.rval <- rep(NA,nrow(cm))
    mmm <- match(cands[,'ICPSR2'],colnames(cm))
    cm <- cm[,mmm]
    ##
    MM <- cm / 100000
    MM <- ceiling(MM)
    MM <- MM / 10
    MM <- ceiling(MM)
    ci.rval.vect <- (rowSums(MM)>1)
    cm <- cm[ci.rval.vect,]

    ##SETTING INITIAL PARAMTERS AT -1 FOR DEMOCRATS AND 1 FOR REPUBLICANS
    if(length(unique(cands[,'party']))>1){
        cands[,'cfscore'] <- ifelse(cands[,'party'] == 100,-1,
                                    ifelse(cands[,'party'] == 200,1,NA))
    }else{
        ko <- which(is.na(cands[,'cfscore']))
        cands[ko,'cfscore'] <- mean(as.numeric(cands[!ko,'cfscore']))
    }

    
    ##
    icpsr = (cands[,'ICPSR'])
    icpsr2 <- (cands[,'ICPSR2'])
    cand.ips <- as.numeric(cands[,'cfscore'])

    mm <- !duplicated(icpsr2)
    cand.ips <- cand.ips[mm]


    for(iter in 1:iters){
        cat('Iteration ',iter,'\n')
        contrib.ips <- get.contrib.means(cm,weights=NULL,cand.ips,
                                         cores=cores,upper.limit=contrib.lim)
        contrib.ips[is.na(contrib.ips)] <- 0
        contrib.ips <- normalize.rows(contrib.ips,rowSums(cm))
        cand.ips <- get.cand.means(cm,contrib.ips,weights=NULL,upper.limit=NA,
                                   dynamic.cands=dynamic.cands,cores=cores)
        cand.ips[is.na(cand.ips)] <- 0
        cand.ips[cand.ips > 4] <- 4
        cand.ips[cand.ips < -4] <- -4
        out <- normalize.cols(cand.ips,colSums(cm))
        cand.ips <- out$x
        scale.param <- out$scale.param
        tt <- match(icpsr2,unique(icpsr2))
        cands[,'cfscore'] <- cand.ips[tt]
    }
    
    contrib.ips.rval <- contrib.ips

    rval <- list(cands = cands,
                 contrib.ips=contrib.ips.rval,
                 scale.param = scale.param)
    return(rval)
}


library(Matrix)

download.file('https://dataverse.harvard.edu/api/access/datafile/2865314?gbrecs=true',
              destfile='mimp.rdata')
print(load('mimp.rdata'))
 
cm <- mimp$cm
cands <- mimp$cands
contributors <- mimp$contribs
cm <- cm[contributors$is.projected ==0,]

cands.in <- cands[grepl('fed',cands[,'seat']),]
cands.in <- cands.in[!duplicated(cands.in[,'ICPSR2']),]

m <- match(cands.in[,'ICPSR2'],colnames(cm))
cm.in <- cm[,m]

MM <- ceiling(cm.in/1e10)
cm.in <- cm.in[rowSums(MM) >= 2,]


out1 <- awm(cands=cands.in,
            cm=cm.in,
            iters = 12)

summary(lm(dwnom1~cfscore,data=out1$cands))
