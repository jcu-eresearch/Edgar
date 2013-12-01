##script to model only species with 20 or more records
##Edgar project 2012
##developed by Lauren Hodgson...lhodgson86@gmail.com
##
## Expects 1 arg, the path to the occurrences file to be tested.

# I don't think this lib is actually necessary for this file...
# library(SDMTools);

args=commandArgs(TRUE);

occur_file=args[1];

toccur=read.csv(paste(occur_file,sep=''));
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
