library(ggplot2);
library(ggalluvial);
library(haven);


Basetot <- read_dta("C:/Users/wb520054/WBG/SARDATALAB - Documents/Microsimulations/SM2026/Oil prices/output/transitions.dta");

ggplot(Basetot, aes(y = value_m, axis1 = country, axis2 = condition_post)) + geom_alluvium(aes(fill = condition_pre), width = 1/12) + geom_stratum(width = 1/12, fill = "gray", color = "black") + geom_label(stat = "stratum", aes(label = after_stat(stratum))) + scale_x_discrete(limits = c("Country - Baseline", "Conflict"), expand = c(.05, .05)) + scale_fill_brewer(type = "qual", palette = "Set2") + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())+ labs(y= "Million people", fill="Class baseline") + ggtitle("Class transitions due to Iran's conflict, South Asia");
ggsave("C:/Users/wb520054/WBG/SARDATALAB - Documents/Microsimulations/SM2026/Oil prices/output/transitions.png", width = 8, height = 5)

Basetot_noIND <- Basetot[Basetot$country != "IND", ]
ggplot(Basetot_noIND, aes(y = value_m, axis1 = country, axis2 = condition_post)) + geom_alluvium(aes(fill = condition_pre), width = 1/12) + geom_stratum(width = 1/12, fill = "gray", color = "black") + geom_label(stat = "stratum", aes(label = after_stat(stratum))) + scale_x_discrete(limits = c("Country - Baseline", "Conflict"), expand = c(.05, .05)) + scale_fill_brewer(type = "qual", palette = "Set2") + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())+ labs(y= "Million people", fill="Class baseline") + ggtitle("Class transitions due to Iran's conflict, South Asia without India");
ggsave("C:/Users/wb520054/WBG/SARDATALAB - Documents/Microsimulations/SM2026/Oil prices/output/transitions_wo_IND.png", width = 8, height = 5)

