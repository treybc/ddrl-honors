##Load libraries
library(pdftools)
library(dplyr)
library(RCurl)
library(stringr)


##Function to download pdf and return error message if file is missing
readUrl <- function(url) {
    out <- tryCatch(
        {
            message("This is the 'try' part")

            download.file(url,
                          destfile=paste0('pdf_',year,'/',c.pdf))
        },
        error=function(cond) {
            message(paste("URL does not seem to exist:", url))
            message("Here's the original error message:")
            message(cond)
            # Choose a return value in case of error
            return(NA)
        },
        warning=function(cond) {
            message(paste("URL caused a warning:", url))
            message("Here's the original warning message:")
            message(cond)
            # Choose a return value in case of warning
            return(NULL)
        },
        finally={
            message(paste("Processed URL:", url))
            message("Some other message at the end")
        }
    )
    return(out)
}


setwd('~/workspace/datasets/candidate_pdf/') #set working directory

year <- 2016 #select cycle

if(FALSE){ # set to TRUE to download csv
    download.file(paste0('http://clerk.house.gov/public_disc/financial-pdfs/',year,'FD.ZIP'),
                         destfile=paste0('cfd_',year,'.zip'))
    unzip(paste0('cfd_',year,'.zip'))
}
qq <- read.csv(paste0(year,'FD.txt'),sep='\t')
qq <- qq[!(qq$FilingType %in% c('P')),]
qq <- qq[substr(qq$DocID,1,1)==1,]


p <- list.files(paste0('pdf_',year))
vect <- 1:nrow(qq)
rm.vect <- c(as.numeric(gsub('\\.pdf','',p)))
vect <- vect[!(qq$DocID %in% rm.vect)]
for(cand in vect){
    inc.max=NA
    inc.sum=NA
    u <- qq$DocID[cand]
    c.pdf <- paste0(u,'.pdf')
    url <- paste0('http://clerk.house.gov/public_disc/financial-pdfs/',year,'/',u,'.pdf')
    vv=readUrl(url)
}

qq <- read.csv(paste0(year,'FD.txt'),sep='\t')
p <- list.files(paste0('pdf_',year))
qq <- qq[match(as.numeric(gsub('\\.pdf','',p)),qq$DocID),]
##qq <- qq[(qq$FilingType %in% c('O','C','A')),]
qq <- qq[substr(qq$DocID,1,1)==1,]

##load(paste0('pfd_cong_',year,'.rda'))
rval <- NULL
vect <- (1:nrow(qq))
for(cand in vect){##[-c(1:nrow(rval))]){
    inc.max=NA
    inc.sum=NA
    networth.mean <- networth.low <- networth.high <- NA
    u <- qq$DocID[cand]

    c.pdf <- paste0('pdf_',year,'/',u,'.pdf')
    oo <- pdf_ocr_text(c.pdf)
    oo1 <- paste(unlist(oo),collapse='\n')
    oo2 <- unlist(str_split(oo1,'\n'))

    str1 <- 'Schedule A'
    str12 <- 'schedule b|schedule c'
    str2 <- 'schedule c: earned income'
    str3 <- 'schedule d: liabilities'

    d1 <- grep(str1,oo2,ignore.case=T)[1]
    d2 <- grep(str12[1],oo2,ignore.case=T)[1]
    tstr <- 'Tax-Deferred|Interest|Dividends|Capital Gains|Rent '

    if(length(d1)>0 & !is.na(d2)){
        ww <- oo2[d1:(d2-1)]

        if(length(ww) > 3){
            i <- (grepl('\\$',ww,ignore.case=T) & !grepl('Type\\(s\\)|^\\$',ww,ignore.case=T))
            ## sp <- str_split_fixed(ww[i],tstr,n=2)
            ## si <- (str_split(sp[,1],'\\$| N\\/',simplify=T))

            am.str <- c('\\$1 -',
                        '\\$1,001 ',
                        '5,001',
                        '15,001',
                        '50,001',
                        '100,001',
                        '250,001',
                        '500,001',
                        '1,000,001',
                        '5,000,001')

            txt <- paste(am.str,collapse='|')
            si <- regmatches(ww[i],regexpr(txt,ww[i]))

            if(length(si)>0){
                am <- as.numeric(gsub(',| |\\-','',si))
            }else{
                am <- NA
            }
            high.am <- ifelse(am == 1,1000,
                       ifelse(am == 1001,5000,
                       ifelse(am == 5001,15000,
                       ifelse(am == 15001,50000,
                       ifelse(am == 50001,100000,
                       ifelse(am == 100001,250000,
                       ifelse(am == 250001,500000,
                       ifelse(am == 500001,1000000,
                       ifelse(am == 1000001,5000000,
                       ifelse(am %% 2 ==0,am,NA))))))))))
            low.am <- ifelse(am != high.am,am,
                      ifelse(am == 1000,1,
                      ifelse(am == 5000,1001,
                      ifelse(am == 15000,5001,
                      ifelse(am == 50000,15001,
                      ifelse(am == 100000,50001,
                      ifelse(am == 250000,100001,
                      ifelse(am == 500000,250001,
                      ifelse(am == 1000000,500001,
                      ifelse(am == 5000000,1000001,NA))))))))))
            lh.am <- cbind(low.am,high.am)
            lh.am <- lh.am[complete.cases(lh.am),]
            if(length(lh.am)==2){
                networth.mean <- mean(lh.am)
                networth.low <- lh.am[1]
                networth.high <- lh.am[2]
            }else{
                networth.mean <- sum(rowMeans(lh.am))
                networth.low <- sum(lh.am[,1])
                networth.high <- sum(lh.am[,2])
            }
        }
    }

    ##extracting income
    p1 <- grep(str2,oo2,ignore.case=T)
    p2 <- grep(str3,oo2,ignore.case=T)
    if(length(p1)>0){
        oo3 <- oo2[p1:(p2-1)]
        i <- grep('\\$',oo3,ignore.case=T)
        income <- oo3[i]
        si <- str_split(income,'\\$| N\\/',simplify=T)
        inc.max <- max(as.numeric(gsub('\\,','',si)),na.rm=T)
        if(is.infinite(inc.max)){
            inc.max=NA
            inc.sum=NA
        }else{
            inc.sum <- sum(as.numeric(gsub('\\,','',si)),na.rm=T)
        }
    }
    rval <- rbind(rval,c(lname=as.character(qq[qq$DocID==u,'Last']),
                         fname=as.character(qq[qq$DocID==u,'First']),
                         DocID=u,
                         networth.low=networth.low,
                         networth.high=networth.high,
                         networth.mean=networth.mean,
                         income=inc.max,income.sum=inc.sum))
    print(rval)
}
save(rval,file=paste0('pfd_cong_',year,'.rda'))

###############################################################################
##MERGE WITH DIME DATA
###############################################################################
load(paste0('pfd_cong_',year,'.rda'))
rval <- as.data.frame(rval)
qq <- read.csv(paste0(year,'FD.txt'),sep='\t')
p <- list.files(paste0('pdf_',year))
qq <- qq[match(as.numeric(gsub('\\.pdf','',p)),qq$DocID),]
qq <- qq[(qq$FilingType %in% c('O','C','A')),]

m <- match(qq$DocID,rval$DocID)
qq <- qq[!is.na(m),]
m <- match(qq$DocID,rval$DocID)
qq <- qq[m,]
qq$networth.mean <- as.numeric(as.character(rval$networth.mean[match(qq$DocID,rval$DocID)]))
qq$networth.low <- as.numeric(as.character(rval$networth.low[match(qq$DocID,rval$DocID)]))
qq$networth.high <- as.numeric(as.character(rval$networth.high[match(qq$DocID,rval$DocID)]))

cong <- read.csv('~/workspace/cong_elections_politico/dime_cong_elections_current.csv')
cong <- cong[cong$cycle==year,]
cmat <- NULL
for(i in 1:nrow(qq)){
    v <- (as.matrix(qq[i,]))
    cc <- cong[which(cong$district == gsub('00','01',as.character(v[,'StateDst']))),]
    io <- grep(v[,'Last'],cc$Name,ignore.case=T)
    if(length(io) >= 1){
        cmat <- rbind(cmat,c(DocID=v[,'DocID'],bonica_rid=as.character(cc[io[1],'bonica_rid'])))
    }else{
        io2 <- agrep(as.character(v[,'Last']),cc$Name,ignore.case=T)
        if(length(io2) ==1){
            cmat <- rbind(cmat,c(DocID=v[,'DocID'],bonica_rid=as.character(cc[io2,'bonica_rid'])))
        }else{
            print(v)

        }
    }
}
qq.tmp <- qq[match(cmat[,1],qq$DocID),]
cong.tmp <- cong[match(cmat[,2],cong$bonica_rid),]
cong.tmp$networth.mean <- qq.tmp$networth.mean
cong.tmp$networth.low <- qq.tmp$networth.low
cong.tmp$networth.high <- qq.tmp$networth.high


cong.tmp$networth.mean[is.na(cong.tmp$networth.mean)] <- 0
zz <- cong.tmp[which(cong.tmp$Incum_Chall != 'I' &
                     cong.tmp$networth.mean > 0 &
                     cong.tmp$candStatus != 'I' &
                     cong.tmp$total_receipts>0 ),]
zz$am.per.donor <- zz$total_receipts/zz$num_distinct_donors
zz$am.per.donor[is.infinite(zz$am.per.donor)] <- NA
summary(lm(log1p(total_receipts)~log1p(networth.high),data=zz))
summary(lm(log1p(total_receipts)~log1p(networth.mean)+Incum_Chall,data=zz,subset=party=='D'))

summary(lm(log1p(total_receipts)~log1p(networth.mean)+Incum_Chall,data=zz,subset=party=='R'))


print( load('~/workspace/sml_election_forecast/data/efilings.rdata'))
