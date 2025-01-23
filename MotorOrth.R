# MotorOrth.R

# Load libraries ----------------------------------------------------------
library(oro.nifti)
library(ggplot2)
library(tidyr)
library(tibble)
library(tbl_summary)
library(ggpmisc)
library(plotrix)
library(emmeans)
library(ggnewscale)
library(DescTools)
library(gridExtra)
library(cowplot)
library(ggsignif)
library(dplyr)

figsdir="/Users/nar423/Library/CloudStorage/OneDrive-SharedLibraries-NorthwesternUniversity/ANVIL - Documents/Projects/Motor_Orthogonalization/Figures/"
onedrive="/Users/nar423/Library/CloudStorage/OneDrive-SharedLibraries-NorthwesternUniversity/ANVIL - Documents/Projects/Motor_Orthogonalization/Data"
nehadir="/Volumes/NR_External/Multiecho_backup_01122024/Multiecho_03162023"
#


# Motion ------------------------------------------------------------------

motValsHH <- read.csv(paste0(onedrive,"/Motion/HealthyHand_MotionVals.csv"))
motValsHS <- read.csv(paste0(onedrive,"/Motion/Shoulder_MotionVals.csv"))
motValsMF <- read.csv(paste0(onedrive,"/Motion/MSFoot_MotionVals.csv"))
motValsMF$Session <- factor(motValsMF$Session,levels=c("ses-01","ses-03"),labels=c("ses-01","ses-02"))
motValsMH <- read.csv(paste0(onedrive,"/Motion/MS_HAND_MotionVals.csv"))
motValsMH$Session <- factor(motValsMH$Session,levels=c("ses-01","ses-03"),labels=c("ses-01","ses-02"))

motVals <- rbind(motValsHH,motValsHS,motValsMF,motValsMH)
motVals$Metric <- factor(motVals$Metric,levels=c("FD","X","Y","Z","Roll","Pitch","Yaw"))
motVals$Task <- factor(motVals$Task,levels=c("Hand","MOTOR10","MOTOR25","MOTOR40","HAND","FOOT"),labels=c("Healthy HandGrasp","Healthy ShAbd 10%","Healthy ShAbd 25%","Healthy ShAbd 40%","MS HandGrasp","MS AnkFlex"))
motVals$Session <- factor(motVals$Session,labels=c("Run 1","Run 2"))

# motVals$Subject <- factor(motVals$Subject,levels=c("sub-02","sub-03","sub-05","sub-09","sub-04","sub-11","sub-10","sub-07"),labels=c(1,2,3,4,5,6,7,8))

pMotCorr <-
  ggplot(data=subset(motVals,Metric!='FD'),mapping=aes(x=Metric,y=Subject)) +
  facet_grid(cols=vars(Session),rows=vars(Task),space="free",scales="free",switch="x") +
  geom_tile(aes(fill=abs(Value))) +
  geom_text(size=2.5,aes(label = round(abs(Value),digits=2),color=ifelse(abs(Value) < 0.6 ,"black","white"))) +
  scale_color_manual(values=c("white","black"),guide=F) +
  scale_fill_viridis_c(limits=c(0,1),
                         guide=guide_colorbar(title.position="top",title.hjust=0.5,title="Correlation | r |")) +
  labs(y="Healthy") +
  theme_void(base_size = 7) +
  scale_x_discrete(position = "top") +
  scale_y_discrete(limits=rev) +
  theme(plot.margin = margin(0, 0, 0, 0.3, "cm")) +
  theme(strip.text = element_text(size = rel(1)))+
  theme(axis.text.x = element_text(),axis.text.y = element_text()) +
    theme(strip.text.y = element_text(angle = 270)) +
  theme(legend.position="top",legend.title = element_text(face="bold",size="9"))

pFD <-
  ggplot(data=subset(motVals,Metric=='FD'),mapping=aes(x=Metric,y=Subject)) +
    facet_grid(cols=vars(Session),rows=vars(Task),space="free",scales="free",switch="x") +
    geom_tile(data=subset(motVals,Metric=='FD' & Value <= 1),aes(fill=abs(Value))) +
    scale_fill_viridis_c(limits=c(0,1),option="magma",
                         guide=guide_colorbar(title.position="top",title.hjust=0.5,title="Average FD (mm)")) +
    ggnewscale::new_scale_fill() +
    geom_tile(data=subset(motVals,Metric=='FD' & Value > 1),mapping = aes(fill = abs(Value) > 1)) +
    scale_fill_manual(NULL,values = "#C0EEEF",labels = "> 1", 
                      guide = guide_legend(order = 2,theme=theme(legend.text.position="bottom"))) +
    geom_text(size=2.5,aes(label = round(abs(Value),digits=2),color=ifelse(abs(Value) < 0.8 ,"black","white"))) +
    scale_color_manual(values=c("white","black"),guide=F) +
    labs(y="Healthy") +
    theme_void(base_size = 7) +
    scale_x_discrete(position = "top") +
    scale_y_discrete(limits=rev) +
    theme(plot.margin = margin(0, 0, 0, 0.3, "cm")) +
    theme(strip.text = element_text(size = rel(1)))+
    theme(axis.text.x = element_text(),axis.text.y = element_text()) +
    theme(strip.text.y = element_text(angle = 270)) +
    theme(legend.position="top",legend.title = element_text(face="bold",size="9"))

fpath=paste(c(figsdir,"motionCorrelations.pdf"),collapse = "")
ggsave(plot = pMotCorr, device = cairo_pdf, width = 5, units="in", height = 8, dpi = 1000,filename = fpath)

fpath=paste(c(figsdir,"FD.pdf"),collapse = "")
ggsave(plot = pFD, device = cairo_pdf, width = 3.54, units="in", height = 8, dpi = 1000,filename = fpath)

pFDCorr <- plot_grid(pFD, pMotCorr, ncol = 2, rel_widths=c(0.5,1))

fpath=paste(c(figsdir,"FDandCorr.pdf"),collapse = "")
ggsave(plot = pFDCorr, device = cairo_pdf, width = 7.5, units="in", height = 8, dpi = 1000,filename = fpath)

#
# tSNR ------------------------------------------------------------------

load.tSNRdata <- function(filename){
  dfname<- read.csv(paste0(onedrive,"/subjectMetrics/",filename),header=F,sep="")
  colnames(dfname) <- c("Group","Subject","Session","Task","Model","ROI","Mean","Median")
  dfname$ROI <- factor(dfname$ROI,levels=c("cortex","cerebellum"),labels=c("Precentral gyrus","Cerebellum"))
  dfname <<- dfname
} 
  
load.tSNRdata("HealthyHand_tSNR.txt")
tSNRHH <- dfname
load.tSNRdata("Shoulder_tSNR.txt")
tSNRHS <- dfname
load.tSNRdata("MSfoot_tSNR.txt")
tSNRMF <- dfname
load.tSNRdata("MSHAND_tSNR.txt")
tSNRMH <- dfname

tSNRHH$Session[tSNRHH$Task == "MOTORmotion"] <- "ses-02"
tSNRHH$Task <- "Hand"
# tSNRHS$Session <- factor(tSNRHS$Session,levels=c("run1","run2"),labels=c("ses-01","ses-02"))
tSNRMF$Session <- factor(tSNRMF$Session,levels=c("ses-01","ses-03"),labels=c("ses-01","ses-02"))

# Add FD column to tSNR datagrame
for (sub in c("sub-02","sub-03","sub-04","sub-05","sub-07","sub-09","sub-10","sub-11")){
  for (ses in c("ses-01","ses-02")){
    data <- subset(motValsHH,Subject==sub & Session==ses & Metric=="FD")
    tSNRHH$FD[tSNRHH$Subject==sub & tSNRHH$Session==ses] <- data$Value
  }
}
for (sub in c("SP-01","SP-05","SP-06","SP-07","SP-08","SP-09","SP-10")){
  for (ses in c("ses-01","ses-02")){
    for (task in c("MOTOR10","MOTOR25","MOTOR40")){
      data <- subset(motValsHS,Subject==sub & Session==ses & Task==task & Metric=="FD")
      tSNRHS$FD[tSNRHS$Subject==sub & tSNRHS$Session==ses & tSNRHS$Task==task] <- data$Value
    }
  }
}
for (sub in c("sub-02","sub-04","sub-05","sub-07","sub-08","sub-10")){
  for (ses in c("ses-01","ses-02")){
    data <- subset(motValsMF,Subject==sub & Session==ses & Metric=="FD")
    tSNRMF$FD[tSNRMF$Subject==sub & tSNRMF$Session==ses] <- data$Value
  }
}

tSNR <- rbind(tSNRHH,tSNRHS,tSNRMF,tSNRMH)
tSNR$Task <- factor(tSNR$Task,levels=c("Hand","MOTOR10","MOTOR25","MOTOR40","HAND","FOOT"),labels=c("HealthyHand","HealthyShoulder 10%","HealthyShoulder 25%","HealthyShoulder 40%","MSHand","MSFoot"))
tSNR$Group <- factor(tSNR$Group,levels=c("HealthyHand","Shoulder","MSHAND","MSfoot"),labels=c("HealthyHand","HealthyShoulder","MSHand","MSFoot"))

tSNR$FD <- as.numeric(tSNR$FD)

sig_df <- data.frame(
  ROI = c("Precentral gyrus"),
  start = c(1.75,2,2.75),
  end = c(2,2.25,3),
  ypos = c(390, 410,150),
  label=c("","",""))
sig_df$ROI <- factor(sig_df$ROI,levels=c("Precentral gyrus","Cerebellum"))
sig_df2 <- data.frame(
  ROI = c("Cerebellum"),
  start = c(0.75,1,1.75,2,2.75),
  end = c(1,1.25,2,2.25,3),
  ypos = c(130, 150,290,310,150),
  label=c("","","","",""))
sig_df2$ROI <- factor(sig_df2$ROI,levels=c("Precentral gyrus","Cerebellum"))

# Plot median tSNR
# pMed <-
  ggplot(data=subset(tSNR),mapping=aes(x=Group,y=Median,fill=Model)) +
  facet_grid(rows=vars(ROI),space="free") +
  geom_boxplot(position="dodge") +
  # geom_jitter()+
  # geom_violin(draw_quantiles = 0.5)+
  # geom_signif(data = sig_df,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  # geom_signif(data = sig_df2,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  scale_fill_brewer(palette = "Dark2") +
  guides(fill=guide_legend(title="Model")) +
  labs(title="Median tSNR in GM") +
  theme_light(base_size = 7) +
  theme(strip.text = element_text(face = "bold", size = rel(0.9),color="black"),
        strip.background = element_rect(fill = "white", colour = "gray", size = 1)) +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(axis.title.x = element_text(size = 7),
        axis.title.y = element_text(size = 7))
    
# Plot tSNR vs FD
# ptSNRvFD <-
  ggplot(data=subset(tSNR),mapping=aes(x=FD,y=Median,color=Model)) +
  facet_grid(cols=vars(Group),rows=vars(ROI)) +
  geom_point(alpha=0.5) +
  geom_smooth(method="lm",se=F) +
  stat_poly_eq(formula = y~x,
               aes(label = paste(..eq.label.., ..rr.label.., p.value.label,sep = "~~~"),group=Model),coef.digits = 3,
               # aes(label = paste(..eq.label..)),coef.digits = 2,
               # aes(label=paste("y=",signif(after_stat(y_estimate),digits=2))),
               label.x = "left",label.y="top",
               parse = TRUE,size=2.5) +
  scale_color_brewer(palette = "Dark2") +
  labs(title="tSNR vs FD",y="Median tSNR",x="FD (mm)") +
  theme_light(base_size = 7) +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(strip.text = element_text(face = "bold", size = rel(0.9),color="black"),
        strip.background = element_rect(fill = "white", colour = "gray", size = 1)) +
  theme(axis.title.x = element_text(size = 7),
          axis.title.y = element_text(size = 7))
  
fpath=paste(c(figsdir,"PRELIM_tSNR.pdf"),collapse = "")
ggsave(plot = pMed, device = cairo_pdf, width = 5, units="in", height = 3.5, dpi = 1000,filename = fpath)

fpath=paste(c(figsdir,"PRELIM_tSNRvFD.pdf"),collapse = "")
ggsave(plot = ptSNRvFD, device = cairo_pdf, width = 5, units="in", height = 3.5, dpi = 1000,filename = fpath)

ptSNRall <- plot_grid(pMed, ptSNRvFD, 
          labels = c("A", "B"), ncol = 1,rel_heights = c(1,1.5))

fpath=paste(c(figsdir,"tSNR.pdf"),collapse = "")
ggsave(plot = ptSNRall, device = cairo_pdf, width = 7.5, units="in", height = 7, dpi = 1000,filename = fpath)

## Stats
mot1 <- subset(tSNR,Group=="MS AnkFlex" & ROI=="Precentral gyrus")
mod1 <- lmer(Median ~ Model + (1|Subject), data = mot1,REML=F)
anova(mod1)
mod1.emm <- emmeans(mod1,pairwise ~ Model,adjust="bonferroni")
mod1.emm

# Spatial correlation ------------------------------------------------------------------

load.corrdata <- function(filename){
  dfname<- read.csv(paste0(onedrive,"/subjectMetrics/",filename),header=F,sep="")
  colnames(dfname) <- c("Group","Subject","Session","Task","Model","Regressor","ROI","Correlation")
  dfname$ROI <- factor(dfname$ROI,levels=c("cortex","cerebellum"),labels=c("Precentral gyrus","Cerebellum"))
  dfname <<- dfname
} 

load.corrdata("HealthyHand_spatialCorr.txt")
corrHH <- dfname
load.corrdata("Shoulder_spatialCorr.txt")
corrHS <- dfname
load.corrdata("MSfoot_spatialCorr.txt")
corrMF <- dfname
load.corrdata("MSHAND_spatialCorr.txt")
corrMH <- dfname

corrHH$Session[corrHH$Task == "MOTORmotion"] <- "ses-02"
corrMF$Session[corrMF$Session == "ses-03"] <- "ses-02"
corrMH$Session[corrMH$Session == "ses-03"] <- "ses-02"

# Add FD column to correlation dataframe - average FD over both runs
for (sub in c("sub-02","sub-03","sub-04","sub-05","sub-07","sub-09","sub-10","sub-11")){
  # for (ses in c("ses-01","ses-02")){
    data1 <- subset(motValsHH,Subject==sub & Session=="ses-01" & Metric=="FD")
    data2 <- subset(motValsHH,Subject==sub & Session=="ses-02" & Metric=="FD")
    corrHH$FD[corrHH$Subject==sub & corrHH$Session=="ses-02"] <- (data1$Value+data2$Value)/2
  # }
}
for (sub in c("SP-01","SP-05","SP-06","SP-07","SP-08","SP-09","SP-10")){
  for (task in c("MOTOR10","MOTOR25","MOTOR40")){
    data1 <- subset(motValsHS,Subject==sub & Session=="ses-01" & Task==task & Metric=="FD")
    data2 <- subset(motValsHS,Subject==sub & Session=="ses-02" & Task==task & Metric=="FD")
    corrHS$FD[corrHS$Subject==sub & corrHS$Task==task & corrHS$Session=="ses-01"] <- (data1$Value+data2$Value)/2
  }
}
for (sub in c("sub-02","sub-04","sub-05","sub-07","sub-08","sub-10")){
  # for (ses in c("ses-01","ses-02")){
  data1 <- subset(motValsMF,Subject==sub & Session=="ses-01" & Metric=="FD")
  data2 <- subset(motValsMF,Subject==sub & Session=="ses-02" & Metric=="FD")
  corrMF$FD[corrMF$Subject==sub & corrMF$Session=="ses-01__ses-03"] <- (data1$Value+data2$Value)/2
  # }
}
for (sub in c("MS-02","MS-03","MS-04","MS-05","MS-07","MS-08","MS-10")){
  # for (ses in c("ses-01","ses-02")){
    data1 <- subset(motValsMH,Subject==sub & Session=="ses-01" & Metric=="FD")
    data2 <- subset(motValsMH,Subject==sub & Session=="ses-02" & Metric=="FD")
    corrMH$FD[corrMH$Subject==sub & corrMH$Session=="ses-01_ses-03"] <- (data1$Value+data2$Value)/2
  # }
}

corrHH$Task <- "HealthyHand"
corrHS$Task <- "HealthyShoulder"
corrMF$Task <- "MSFoot"
corrMH$Task <- "MSHand"
corr <- rbind(corrHH,corrHS,corrMF,corrMH)
corr$Task <- factor(corr$Task, levels = c("HealthyHand","HealthyShoulder","MSHand","MSFoot"))

corr$FD <- as.numeric(corr$FD)

# Create FD bins
corr <- corr %>%
  mutate(FDbin = case_when(
    FD <= 0.25 ~ "Low",
    FD > 0.25 & FD <= 0.5 ~ "Moderate",
    FD > 0.5 ~ "High",
    TRUE ~ NA_character_
  ))

corr <- corr %>%
  mutate(Signal = case_when(
    Task == "HealthyHand" ~ "High Signal",
    Task == "HealthyShoulder" ~ "Low Signal",
    Task == "MSHand" ~ "High Signal",
    Task == "MSFoot" ~ "Low Signal",
    TRUE ~ NA_character_
  ))

corr$FDbin <- factor(corr$FDbin, levels = c("Low","Moderate","High"),labels=c("Low (FD \u2264 0.25)","Moderate (0.25 < FD \u2264 0.5)","High (FD > 0.5)"))
corr$Model <- factor(corr$Model,levels=c("Basic","TaskCorr","ConsOrth"),labels=c("Agg","TaskCorr","Cons"))


# Plot spatial correlations
sig_df <- data.frame(
  ROI = c("Precentral gyrus"),
  start = c(0.75,0.75,1.75,2),
  end = c(1,1.25,2,2.25),
  ypos = c(0.8, 0.85,0.8,0.85),
  label=c("","","",""))
sig_df$ROI <- factor(sig_df$ROI,levels=c("Precentral gyrus","Cerebellum"))
sig_df2 <- data.frame(
  ROI = c("Cerebellum"),
  start = c(0.75,0.75,1.75,2),
  end = c(1,1.25,2,2.25),
  ypos = c(0.5, 0.55,0.75,0.8),
  label=c("","","",""))
sig_df2$ROI <- factor(sig_df2$ROI,levels=c("Precentral gyrus","Cerebellum"))

# pCorr <-
  ggplot(data=subset(corr),mapping=aes(x=Task,y=Correlation,fill=Model)) +
  geom_boxplot(position="dodge") +
  # geom_jitter()+
  # geom_violin(draw_quantiles = 0.5)+
  facet_grid(rows=vars(ROI)) +
  # geom_signif(data = sig_df,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  # geom_signif(data = sig_df2,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  scale_fill_brewer(palette = "Dark2") +
  guides(fill=guide_legend(title="Model")) +
  labs(title="Spatial correlation in GM",y="Spatial correlation (r)") +
  theme_light(base_size = 7) +
  theme(strip.text = element_text(face = "bold", size = rel(0.9),color="black"),
        strip.background = element_rect(fill = "white", colour = "gray", size = 1)) +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(axis.title.x = element_text(size = 7),
        axis.title.y = element_text(size = 7))

# Plot spatial correlation vs FD bins
 pCorrFDbins <-
   ggplot(data=subset(corr,FDbin!="NA"),mapping=aes(x=FDbin,y=Correlation,fill=Model)) +
  geom_boxplot(position="dodge",outlier.shape=NA) +
  geom_jitter(position=position_jitterdodge(jitter.width = 0.4, dodge.width = 0.75),aes(group=Model,shape=Task),size=0.7)+
   scale_shape_manual(values = c(16, 17, 5, 3)) +
  # geom_violin(draw_quantiles = 0.5)+
  facet_grid(rows=vars(ROI),cols=vars(Signal)) +
  # geom_signif(data = sig_df,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  # geom_signif(data = sig_df2,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  scale_fill_brewer(palette = "Dark2") +
  guides(fill=guide_legend(title="Model")) +
  labs(title="Spatial correlation in GM",y="Spatial correlation (r)") +
  theme_light(base_size = 7) +
  theme(strip.text = element_text(face = "bold", size = rel(0.9),color="black"),
        strip.background = element_rect(fill = "white", colour = "gray", size = 1)) +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(axis.title.x = element_text(size = 7),
        axis.title.y = element_text(size = 7))
  
# pCorrvFD <-
  ggplot(data=subset(corr),mapping=aes(x=FD,y=Correlation,color=Model)) +
  facet_grid(cols=vars(Task),rows=vars(ROI)) +
  geom_point(alpha=0.5) +
  geom_smooth(method="lm",se=F) +
  scale_color_brewer(palette = "Dark2") +
  stat_poly_eq(formula = y~x,
               aes(label = paste(..eq.label.., ..rr.label.., p.value.label,sep = "~~~"),group=Model),coef.digits = 2,
               # aes(label = paste(..eq.label..)),coef.digits = 2,
               # aes(label=paste("y=",signif(after_stat(y_estimate),digits=2))),
               label.x = "left",label.y="top",
               parse = TRUE,size=2.5) +
  labs(title="Spatial correlation vs FD in GM",y="Spatial correlation (r)",x="Average FD over both runs (mm)") +
  theme_light(base_size = 7) +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(strip.text = element_text(face = "bold", size = rel(0.9),color="black"),
        strip.background = element_rect(fill = "white", colour = "gray", size = 1)) +
  theme(axis.title.x = element_text(size = 7),
        axis.title.y = element_text(size = 7))

fpath=paste(c(figsdir,"PRELIM_spatialCorr.pdf"),collapse = "")
ggsave(plot = pCorr, device = cairo_pdf, width = 7.5, units="in", height = 3.5, dpi = 1000,filename = fpath)

fpath=paste(c(figsdir,"SpatialCorr_FDbins.pdf"),collapse = "")
ggsave(plot = pCorrFDbins, device = cairo_pdf, width = 7.5, units="in", height = 6, dpi = 1000,filename = fpath)

pSpCorrall <- plot_grid(pCorr, pCorrvFD, 
                      labels = c("A", "B"), ncol = 1,rel_heights = c(1,1.5))

fpath=paste(c(figsdir,"spatialCorrelation.pdf"),collapse = "")
ggsave(plot = pSpCorrall, device = cairo_pdf, width = 7.5, units="in", height = 7, dpi = 1000,filename = fpath)

## Stats
mot1 <- subset(corr,Task=="MS AnkFlex" & ROI=="Cerebellum")
mod1 <- lmer(Correlation ~ Model + (1|Subject), data = mot1,REML=F)
anova(mod1)
mod1.emm <- emmeans(mod1,pairwise ~ Model,adjust="bonferroni")
mod1.emm

#
# t-stat ------------------------------------------------------------------

load.tstatdata <- function(filename){
  dfname<- read.csv(paste0(onedrive,"/subjectMetrics/",filename),header=F,sep="")
  colnames(dfname) <- c("Group","Subject","Session","Task","Model","Regressor","ROI","MeanTstat","MedianTstat")
  dfname$ROI <- factor(dfname$ROI,levels=c("cortex","cerebellum"),labels=c("Precentral gyrus","Cerebellum"))
  dfname <<- dfname
} 

load.tstatdata("HealthyHand_tstat.txt")
tstatHH <- dfname
load.tstatdata("Shoulder_tstat.txt")
tstatHS <- dfname
load.tstatdata("MSfoot_tstat.txt")
tstatMF <- dfname
load.tstatdata("MSHAND_tstat.txt")
tstatMH <- dfname

tstatHH$Session[tstatHH$Task == "MOTORmotion"] <- "ses-02"
tstatMF$Session[tstatMF$Session == "ses-03"] <- "ses-02"
tstatMH$Session[tstatMH$Session == "ses-03"] <- "ses-02"

# Add FD column to datagrame
for (sub in c("sub-02","sub-03","sub-04","sub-05","sub-07","sub-09","sub-10","sub-11")){
  for (ses in c("ses-01","ses-02")){
    data <- subset(motValsHH,Subject==sub & Session==ses & Metric=="FD")
    tstatHH$FD[tstatHH$Subject==sub & tstatHH$Session==ses] <- data$Value
  }
}
for (sub in c("SP-01","SP-05","SP-06","SP-07","SP-08","SP-09","SP-10")){
  for (ses in c("ses-01","ses-02")){
    for (task in c("MOTOR10","MOTOR25","MOTOR40")){
      data <- subset(motValsHS,Subject==sub & Session==ses & Task==task & Metric=="FD")
      tstatHS$FD[tstatHS$Subject==sub & tstatHS$Session==ses & tstatHS$Task==task] <- data$Value
    }
  }
}
for (sub in c("sub-02","sub-04","sub-05","sub-07","sub-08","sub-10")){
  for (ses in c("ses-01","ses-02")){
    data <- subset(motValsMF,Subject==sub & Session==ses & Metric=="FD")
    tstatMF$FD[tstatMF$Subject==sub & tstatMF$Session==ses] <- data$Value
  }
}
for (sub in c("MS-02","MS-03","MS-04","MS-05","MS-07","MS-08","MS-10")){
  for (ses in c("ses-01","ses-02")){
    data <- subset(motValsMH,Subject==sub & Session==ses & Metric=="FD")
    tstatMH$FD[tstatMH$Subject==sub & tstatMH$Session==ses] <- data$Value
  }
}


tstatHH$Task <- "HealthyHand"
tstatHS$Task <- "HealthyShoulder"
tstatMF$Task <- "MSFoot"
tstatMH$Task <- "MSHand"
tstat <- rbind(tstatHH,tstatHS,tstatMF,tstatMH)
tstat$Task <- factor(tstat$Task, levels = c("HealthyHand","HealthyShoulder","MSHand","MSFoot"))

tstat$FD <- as.numeric(tstat$FD)

# Create FD bins
tstat <- tstat %>%
  mutate(FDbin = case_when(
    FD <= 0.25 ~ "Low",
    FD > 0.25 & FD <= 0.5 ~ "Moderate",
    FD > 0.5 ~ "High",
    TRUE ~ NA_character_
  ))
tstat <- tstat %>%
  mutate(Signal = case_when(
    Task == "HealthyHand" ~ "High Signal",
    Task == "HealthyShoulder" ~ "Low Signal",
    Task == "MSHand" ~ "High Signal",
    Task == "MSFoot" ~ "Low Signal",
    TRUE ~ NA_character_
  ))

tstat$FDbin <- factor(tstat$FDbin, levels = c("Low","Moderate","High"),labels=c("Low (FD \u2264 0.25)","Moderate (0.25 < FD \u2264 0.5)","High (FD > 0.5)"))
tstat$Model <- factor(tstat$Model,levels=c("Basic","TaskCorr","ConsOrth"),labels=c("Agg","TaskCorr","Cons"))

# Plot t-statistics
sig_df <- data.frame(
  ROI = c("Precentral gyrus"),
  start = c(0.75,0.75,1.75,2),
  end = c(1,1.25,2,2.25),
  ypos = c(2.7, 3,2.7,3),
  label=c("","","",""))
sig_df$ROI <- factor(sig_df$ROI,levels=c("Precentral gyrus","Cerebellum"))
sig_df2 <- data.frame(
  ROI = c("Cerebellum"),
  start = c(1.75,2,2.75),
  end = c(2,2.25,3),
  ypos = c(1.6, 1.9,2.8),
  label=c("","",""))
sig_df2$ROI <- factor(sig_df2$ROI,levels=c("Precentral gyrus","Cerebellum"))

# pTstat <-
  ggplot(data=subset(tstat),mapping=aes(x=Task,y=MedianTstat,fill=Model)) +
  geom_boxplot(position="dodge") +
  # geom_jitter()+
  # geom_violin(draw_quantiles = 0.5)+
  facet_grid(rows=vars(ROI)) +
  # geom_signif(data = sig_df,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  # geom_signif(data = sig_df2,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  scale_fill_brewer(palette = "Dark2") +
  guides(fill=guide_legend(title="Model")) +
  labs(title="Median t-statistic",y="Median t-statistic") +
  theme_light(base_size = 7) +
  theme(strip.text = element_text(face = "bold", size = rel(0.9),color="black"),
        strip.background = element_rect(fill = "white", colour = "gray", size = 1)) +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(axis.title.x = element_text(size = 7),
        axis.title.y = element_text(size = 7))

sig_df <- data.frame(
  ROI = c("Precentral gyrus"),
  start = c(0.75,0.75,1.75),
  end = c(1,1.25,2.25),
  ypos = c(2.7, 2.9,2.7),
  label=c("","",""))
sig_df$ROI <- factor(sig_df$ROI,levels=c("Precentral gyrus","Cerebellum"))
sig_df2 <- data.frame(
  ROI = c("Cerebellum"),
  start = c(0.75,1.75,1.75),
  end = c(1.25,2.25,2),
  ypos = c(2.6, 2.2,2),
  label=c("","",""))
sig_df2$ROI <- factor(sig_df2$ROI,levels=c("Precentral gyrus","Cerebellum"))
  
# Plot tSNR vs FD bins
# pTstat <-
  ggplot(data=subset(tstat,FDbin!="NA"),mapping=aes(x=FDbin,y=MedianTstat,fill=Model)) +
  geom_boxplot(position="dodge") +
  # geom_jitter(size=0.7,position=position_jitterdodge(jitter.width=0.2,dodge.width=0.75))+
  # geom_violin(draw_quantiles = 0.5)+
  facet_grid(rows=vars(ROI),cols=vars(Signal)) +
  # geom_signif(data = sig_df,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  # geom_signif(data = sig_df2,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  scale_fill_brewer(palette = "Dark2") +
  guides(fill=guide_legend(title="Model")) +
  labs(title="Median t-statistic",y="Median t-statistic") +
  theme_light(base_size = 7) +
  theme(strip.text = element_text(face = "bold", size = rel(0.9),color="black"),
        strip.background = element_rect(fill = "white", colour = "gray", size = 1)) +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(axis.title.x = element_text(size = 7),
        axis.title.y = element_text(size = 7))
  
# pCorrvFD <-
ggplot(data=subset(tstat),mapping=aes(x=FD,y=Correlation,color=Model)) +
  facet_grid(cols=vars(Task),rows=vars(ROI),scales="free") +
  geom_point(alpha=0.5) +
  geom_smooth(method="lm",se=F) +
  scale_color_brewer(palette = "Dark2") +
  labs(title="Spatial correlation vs Amplified motion FD",y="Spatial correlation (r)",x="Average FD over both runs (mm)") +
  theme_light(base_size = 7) +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(strip.text = element_text(face = "bold", size = rel(0.9),color="black"),
        strip.background = element_rect(fill = "white", colour = "gray", size = 1)) +
  theme(axis.title.x = element_text(size = 7),
        axis.title.y = element_text(size = 7))

fpath=paste(c(figsdir,"tstat.pdf"),collapse = "")
ggsave(plot = pTstat , device = cairo_pdf, width = 7.5, units="in", height = 3.5, dpi = 1000,filename = fpath)

fpath=paste(c(figsdir,"PRELIM_CorrvFD.pdf"),collapse = "")
ggsave(plot = pCorrvFD, device = cairo_pdf, width = 7.5, units="in", height = 3.5, dpi = 1000,filename = fpath)


## Stats
mot1 <- subset(tstat,FDbin=="Moderate" & ROI=="Precentral gyrus")
mod1 <- lmer(MedianTstat ~ Model + (1|Subject), data = mot1,REML=F)
anova(mod1)
mod1.emm <- emmeans(mod1,pairwise ~ Model,adjust="bonferroni")
mod1.emm

#
# Activation ------------------------------------------------------------------

load.actdata <- function(filename){
  dfname<- read.csv(paste0(onedrive,"/subjectMetrics/",filename),header=F,sep="")
  colnames(dfname) <- c("Group","Subject","Session","Task","Model","Regressor","ROI","MeanBcoef","MedianBcoef","PerAct")
  dfname$ROI <- factor(dfname$ROI,levels=c("cortex","cerebellum"),labels=c("Precentral gyrus","Cerebellum"))
  dfname$PerAct <- dfname$PerAct*100
  dfname$MeanBcoef <- dfname$MeanBcoef*100
  dfname$MedianBcoef <- dfname$MedianBcoef*100
  dfname <<- dfname
} 

load.actdata("HealthyHand_activation.txt")
actHH <- dfname
load.actdata("Shoulder_activation.txt")
actHS <- dfname
load.actdata("MSfoot_Activation.txt")
actMF <- dfname
load.actdata("MSHAND_Activation.txt")
actMH <- dfname

actHH$Session[actHH$Task == "MOTORmotion"] <- "ses-02"
actMF$Session[actMF$Session == "ses-03"] <- "ses-02"
actMH$Session[actMH$Session == "ses-03"] <- "ses-02"

# Add FD column to datagrame
for (sub in c("sub-02","sub-03","sub-04","sub-05","sub-07","sub-09","sub-10","sub-11")){
  for (ses in c("ses-01","ses-02")){
    data <- subset(motValsHH,Subject==sub & Session==ses & Metric=="FD")
    actHH$FD[actHH$Subject==sub & actHH$Session==ses] <- data$Value
  }
}
for (sub in c("SP-01","SP-05","SP-06","SP-07","SP-08","SP-09","SP-10")){
  for (ses in c("ses-01","ses-02")){
    for (task in c("MOTOR10","MOTOR25","MOTOR40")){
      data <- subset(motValsHS,Subject==sub & Session==ses & Task==task & Metric=="FD")
      actHS$FD[actHS$Subject==sub & actHS$Session==ses & actHS$Task==task] <- data$Value
    }
  }
}
for (sub in c("sub-02","sub-04","sub-05","sub-07","sub-08","sub-10")){
  for (ses in c("ses-01","ses-02")){
    data <- subset(motValsMF,Subject==sub & Session==ses & Metric=="FD")
    actMF$FD[actMF$Subject==sub & actMF$Session==ses] <- data$Value
  }
}
for (sub in c("MS-02","MS-03","MS-04","MS-05","MS-07","MS-08","MS-10")){
  for (ses in c("ses-01","ses-02")){
    data <- subset(motValsMH,Subject==sub & Session==ses & Metric=="FD")
    actMH$FD[actMH$Subject==sub & actMH$Session==ses] <- data$Value
  }
}


actHH$Task <- "HealthyHand"
actHS$Task <- "HealthyShoulder"
actMF$Task <- "MSFoot"
actMH$Task <- "MSHand"
act <- rbind(actHH,actHS,actMF,actMH)
act$Task <- factor(act$Task, levels = c("HealthyHand","HealthyShoulder","MSHand","MSFoot"))

act$FD <- as.numeric(act$FD)

# Create FD bins
act <- act %>%
  mutate(FDbin = case_when(
    FD <= 0.25 ~ "Low",
    FD > 0.25 & FD <= 0.5 ~ "Moderate",
    FD > 0.5 ~ "High",
    TRUE ~ NA_character_
  ))

act <- act %>%
  mutate(Signal = case_when(
    Task == "HealthyHand" ~ "High Signal",
    Task == "HealthyShoulder" ~ "Low Signal",
    Task == "MSHand" ~ "High Signal",
    Task == "MSFoot" ~ "Low Signal",
    TRUE ~ NA_character_
  ))

act$FDbin <- factor(act$FDbin, levels = c("Low","Moderate","High"),labels=c("Low (FD \u2264 0.25)","Moderate (0.25 < FD \u2264 0.5)","High (FD > 0.5)"))
act$Model <- factor(act$Model,levels=c("Basic","TaskCorr","ConsOrth"),labels=c("Agg","TaskCorr","Cons"))


# Plot activation metrics
sig_df <- data.frame(
  ROI = c("Precentral gyrus"),
  start = c(0.75,0.75,2.75,3),
  end = c(1,1.25,3,3.25),
  ypos = c(1.2, 1.5,1.9,2.2),
  label=c("","","",""))
sig_df$ROI <- factor(sig_df$ROI,levels=c("Precentral gyrus","Cerebellum"))
sig_df2 <- data.frame(
  ROI = c("Cerebellum"),
  start = c(2.75),
  end = c(3),
  ypos = c(1.9),
  label=c(""))
sig_df2$ROI <- factor(sig_df2$ROI,levels=c("Precentral gyrus","Cerebellum"))
# pBcoef <-
  ggplot(data=subset(act),mapping=aes(x=Task,y=MedianBcoef,fill=Model)) +
  geom_boxplot(position="dodge") +
  # geom_point(position=position_dodge(width=0.75)) +
  facet_grid(rows=vars(ROI)) +
  # geom_violin(draw_quantiles = 0.5)+
  # geom_signif(data = sig_df,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  # geom_signif(data = sig_df2,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  scale_fill_brewer(palette = "Dark2") +
  guides(fill=guide_legend(title="Model")) +
  labs(title="Median beta coefficient",y="% signal change") +
  theme_light(base_size = 7) +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(strip.text = element_text(face = "bold", size = rel(0.9),color="black"),
        strip.background = element_rect(fill = "white", colour = "gray", size = 1)) +
  theme(axis.title.x = element_text(size = 7),
        axis.title.y = element_text(size = 7))

# Plot percent activated in ROI
sig_df <- data.frame(
  ROI = c("Precentral gyrus"),
  start = c(0.75,0.75,1.75,2),
  end = c(1,1.25,2,2.25),
  ypos = c(48, 52,53,57),
  label=c("","","",""))
sig_df$ROI <- factor(sig_df$ROI,levels=c("Precentral gyrus","Cerebellum"))
sig_df2 <- data.frame(
  ROI = c("Cerebellum"),
  start = c(1.75,2),
  end = c(2,2.25),
  ypos = c(38, 42),
  label=c("",""))
sig_df2$ROI <- factor(sig_df2$ROI,levels=c("Precentral gyrus","Cerebellum"))
pPerAct <-
  ggplot(data=subset(act),mapping=aes(x=Task,y=PerAct,fill=Model)) +
    geom_boxplot(position="dodge") +
    # geom_point(position=position_dodge(width=0.75)) +
    facet_grid(rows=vars(ROI)) +
    # geom_violin(draw_quantiles = 0.5)+
    # geom_signif(data = sig_df,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
    # geom_signif(data = sig_df2,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
    scale_fill_brewer(palette = "Dark2") +
    guides(fill=guide_legend(title="Model")) +
    labs(title="Percent activated voxels",y="% activated voxels") +
    theme_light(base_size = 7) +
    theme(plot.title = element_text(hjust = 0.5)) +
    theme(strip.text = element_text(face = "bold", size = rel(0.9),color="black"),
          strip.background = element_rect(fill = "white", colour = "gray", size = 1)) +
    theme(axis.title.x = element_text(size = 7),
          axis.title.y = element_text(size = 7))

fpath=paste(c(figsdir,"PRELIM_bcoef.pdf"),collapse = "")
ggsave(plot = pBcoef, device = cairo_pdf, width = 3.5, units="in", height = 3.5, dpi = 1000,filename = fpath)

fpath=paste(c(figsdir,"PRELIM_percentActivated.pdf"),collapse = "")
ggsave(plot = pPerAct, device = cairo_pdf, width = 3.5, units="in", height = 3.5, dpi = 1000,filename = fpath)

## FD bins
# pBcoef <-
  ggplot(data=subset(act,FDbin!="NA"),mapping=aes(x=FDbin,y=MedianBcoef,fill=Model)) +
  geom_boxplot(position="dodge") +
  # geom_point(position=position_dodge(width=0.75)) +
  facet_grid(rows=vars(ROI),cols=vars(Signal)) +
  # geom_violin(draw_quantiles = 0.5)+
  # geom_signif(data = sig_df,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  # geom_signif(data = sig_df2,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  scale_fill_brewer(palette = "Dark2") +
  guides(fill=guide_legend(title="Model")) +
  labs(title="Median beta coefficient",y="% signal change") +
  theme_light(base_size = 7) +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(strip.text = element_text(face = "bold", size = rel(0.9),color="black"),
        strip.background = element_rect(fill = "white", colour = "gray", size = 1)) +
  theme(axis.title.x = element_text(size = 7),
        axis.title.y = element_text(size = 7))

# pPerAct <-
  ggplot(data=subset(act,FDbin!="NA"),mapping=aes(x=FDbin,y=PerAct,fill=Model)) +
  geom_boxplot(position="dodge") +
  # geom_point(position=position_dodge(width=0.75)) +
  facet_grid(rows=vars(ROI),cols=vars(Signal)) +
  # geom_violin(draw_quantiles = 0.5)+
  # geom_signif(data = sig_df,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  # geom_signif(data = sig_df2,aes(xmin=start,xmax=end,annotations=label,y_position=ypos),tip_length = 0,manual=TRUE,inherit.aes = FALSE) +
  scale_fill_brewer(palette = "Dark2") +
  guides(fill=guide_legend(title="Model")) +
  labs(title="Percent activated voxels",y="% activated voxels") +
  theme_light(base_size = 7) +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(strip.text = element_text(face = "bold", size = rel(0.9),color="black"),
        strip.background = element_rect(fill = "white", colour = "gray", size = 1)) +
  theme(axis.title.x = element_text(size = 7),
        axis.title.y = element_text(size = 7))

## Stats
mot1 <- subset(act,Task=="MS AnkFlex" & ROI=="Precentral gyrus")
mod1 <- lmer(PerAct ~ Model + (1|Subject), data = mot1,REML=F)
anova(mod1)
mod1.emm <- emmeans(mod1,pairwise ~ Model,adjust="bonferroni")
mod1.emm

pActStats <- plot_grid(pBcoef,pPerAct,pTstat,cols = 1,labels=c("A","B","C"))

fpath=paste(c(figsdir,"DRAFT_ActivationMetrics.pdf"),collapse = "")
ggsave(plot = pActStats, device = cairo_pdf, width = 7.5, units="in", height = 9, dpi = 1000,filename = fpath)
