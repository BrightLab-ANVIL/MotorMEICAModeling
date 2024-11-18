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

paperdir="/Volumes/NR_External/ShoulderPilot/Figures/"
#


# Motion ------------------------------------------------------------------

motVals <- read.csv("/Volumes/NR_External/Multiecho_backup_01122024/Multiecho_03162023/HealthyHand_MotionVals.csv")
# hCorrTidy <- pivot_longer(hCorr,cols=3:6,names_to="FD",values_to="FDval")
# hCorrTidy <- pivot_longer(hCorrTidy,cols=3:8,names_to="Mot_rval",values_to="Mot_rval_val")
# hCorrTidy$Mot_rval <- factor(hCorrTidy$Mot_rval,levels=c("z_rval","y_rval","x_rval","yaw_rval","pit_rval","roll_rval"),labels=c("X","Y","Z","Roll","Pitch","Yaw"))
# colnames(hCorrTidy)[1] <- "Subject" 
# colnames(hCorrTidy)[2] <- "Task" 
# colnames(hCorrTidy)[5] <- "Direction" 
# colnames(hCorrTidy)[6] <- "Correlation" 
# hCorrTidy$Subject <- factor(hCorrTidy$Subject,levels=c(2,3,5,9,4,11,10,7,6,8,12,13),labels=c(1,2,3,4,5,6,7,8,9,10,11,12))
# hCorrTidy$Task <- factor(hCorrTidy$Task,levels=c(1,2),labels=c("Limited","Amplified"))

# pCorr <-
  ggplot(data=subset(motVals,Metric!='FD'),mapping=aes(x=Metric,y=Subject)) +
  facet_grid(cols=vars(Task),switch="both") +
  geom_tile(aes(fill=abs(Value))) +
  geom_text(size=2.5,aes(label = round(abs(Value),digits=2),color=ifelse(abs(Value) < 0.75 ,"black","white"))) +
  scale_color_manual(values=c("white","black"),guide=F) +
  scale_fill_viridis_c(limits=c(0,1),
                         guide=guide_colorbar(title.position="top",title.hjust=0.5,title="Correlation | r |")) +
  labs(y="Healthy") +
  theme_void(base_size = 7) +
  scale_x_discrete(position = "top") +
  scale_y_discrete(limits=rev) +
  theme(plot.margin = margin(0, 0, 0, 0.3, "cm")) +
  theme(strip.text = element_text(size = rel(1)))+
  theme(axis.title.x = element_text(),
        # axis.title.y = element_text(angle = 90),
        axis.text.x = element_text()) +
  theme(axis.title.x = element_text(size = 7))+
  # axis.title.y = element_text(size = 7,angle=90)) +
  theme(axis.title.x = element_text(size = 7,margin=margin(b=3))) +
  theme(legend.position="top",legend.title = element_text(face="bold",size="9"))
  
# pFD <-
  ggplot(data=subset(motVals,Metric=='FD'),mapping=aes(x=Metric,y=Subject)) +
    facet_grid(cols=vars(Task),switch="both") +
    geom_tile(aes(fill=abs(Value))) +
    geom_text(size=2.5,aes(label = round(abs(Value),digits=2),color=ifelse(abs(Value) < 1 ,"black","white"))) +
    scale_color_manual(values=c("white","black"),guide=F) +
    scale_fill_viridis_c(limits=c(0,2.5),option="magma",
                         guide=guide_colorbar(title.position="top",title.hjust=0.5,title="Average FD (mm)")) +
    labs(y="Healthy") +
    theme_void(base_size = 7) +
    scale_x_discrete(position = "top") +
    scale_y_discrete(limits=rev) +
    theme(plot.margin = margin(0, 0, 0, 0.3, "cm")) +
    theme(strip.text = element_text(size = rel(1)))+
    theme(axis.title.x = element_text(),
          # axis.title.y = element_text(angle = 90),
          axis.text.x = element_text()) +
    theme(axis.title.x = element_text(size = 7))+
    # axis.title.y = element_text(size = 7,angle=90)) +
    theme(axis.title.x = element_text(size = 7,margin=margin(b=3))) +
    theme(legend.position="top",legend.title = element_text(face="bold",size="9"))
