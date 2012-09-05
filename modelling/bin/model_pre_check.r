##script to model only species with 20 or more records
##Edgar project 2012
##developed by Lauren Hodgson...lhodgson86@gmail.com

library(SDMTools);

wd='/scratch/jc155857/EdgarMaster/modelling/inputs/';

spp='1'; #define spp object.  needs to correspond to $SPP arg in bash
occur='public_occur.csv'; #define occur object. needs to correspond to $OCCUR

toccur=read.csv(paste(wd,spp,'/',occur,sep=''));
toccur$LATDEC = round(toccur$LATDEC/0.05)*0.05;
toccur$LONGDEC = round(toccur$LONGDEC/0.05)*0.05;

toccur=unique(toccur); #find only unique records

pointcount=nrow(toccur);

if (pointcount >20) {
    #run the model
    q(status=0);
} else {
    #don't run the model
    q(status=1);
}
