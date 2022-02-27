# 
# ## About the data
# #### Mental Health in Tech Survey
# Survey on Mental Health in the Tech Workplace in 2014 [Link](https://www.kaggle.com/osmi/mental-health-in-tech-survey)  
  
# This dataset contains the following data:  
# 1. `Timestamp`  
# 2. `Age`  
# 3. `Gender`  
# 4. `Country`  
# 5. `state`: If you live in the United States, which state or territory do you live in?  
# 6. `self_employed`: Are you self-employed?  
# 7. `family_history`: Do you have a family history of mental illness?  
# 8. `treatment`: Have you sought treatment for a mental health condition?  
# 9. `work_interfere`: If you have a mental health condition, do you feel that it interferes with your work?  
# 10. `no_employees`: How many employees does your company or organization have?  
# 11. `remote_work`: Do you work remotely (outside of an office) at least 50% of the time?  
# 12. `tech_company`: Is your employer primarily a tech company/organization?  
# 13. `benefits`: Does your employer provide mental health benefits?  
# 14. `care_options`: Do you know the options for mental health care your employer provides?  
# 15. `wellness_program`: Has your employer ever discussed mental health as part of an employee wellness program?  
# 16. `seek_help`: Does your employer provide resources to learn more about mental health issues and how to seek help?  
# 17. `anonymity`: Is your anonymity protected if you choose to take advantage of mental health or substance abuse treatment resources?  
# 18. `leave`: How easy is it for you to take medical leave for a mental health condition?  
# 19. `mentalhealthconsequence`: Do you think that discussing a mental health issue with your employer would have negative consequences?  
# 20. `physhealthconsequence`: Do you think that discussing a physical health issue with your employer would have negative consequences?  
# 21. `coworkers`: Would you be willing to discuss a mental health issue with your coworkers?  
# 22. `supervisor`: Would you be willing to discuss a mental health issue with your direct supervisor(s)?  
# 23. `mentalhealthinterview`: Would you bring up a mental health issue with a potential employer in an interview?  
# 24. `physhealthinterview`: Would you bring up a physical health issue with a potential employer in an interview?  
# 25. `mentalvsphysical`: Do you feel that your employer takes mental health as seriously as physical health?  
# 26. `obs_consequence`: Have you heard of or observed negative consequences for coworkers with mental health conditions in your workplace?  
# 27. `comments`: Any additional notes or comments    
  
  
  
## Analysing the data
library(tidyverse)
library(ggrepel)
library(hrbrthemes)
library(viridis)
library(RColorBrewer)
library(gridExtra)
library(ggalluvial)
library(wordcloud)
library(tidytext)
library(reshape2)
library(corrplot)
library(ggcorrplot)
library(tm)
library(grid)
library(heatmaply)
library(tidyr)

# reading the file
df_mental_health <- read.csv('mental-health-survey.csv', na.strings = c('', 'NA'), stringsAsFactors = T)
head(df_mental_health) # checking the dataset

# checking the unique values in the Gender column
unique(df_mental_health$Gender)

# converting the column values to lowercase
df_mental_health$Gender <- tolower(df_mental_health$Gender)

# defining lists on the basis of unique values present in the dataset
male <- c('male-ish', 'cis male', 'male (cis)', 'make', 'mail', 'ostensibly male, unsure what that really means', 'm', 'maile', 'male ', 'msle', 'mal', 'man', 'malr', 'cis man', 'male')
female <- c('female', 'female ', 'female (cis)', 'woman', 'cis female', 'cis-female/femme', 'femail', 'f', 'femake')
others <- c('p', 'nah', 'all', 'a little about you', 'genderqueer', 'non-binary', 'trans woman', 'androgyne', 'neuter', 'trans-female', 'agender', 'female (trans)', 'something kinda male?', 'enby', 'guy (-ish) ^_^', 'queer', 'queer/she/they', 'male leaning androgynous', 'fluid', 'genderqueer', 'non-binary', 'trans woman', 'androgyne', 'neuter', 'trans-female', 'agender', 'female (trans)', 'something kinda male?', 'enby', 'guy (-ish) ^_^', 'queer', 'queer/she/they', 'male leaning androgynous', 'fluid')

# replace the values in the data set so that the categories are consistent
df_mental_health <- df_mental_health %>% mutate(Gender = replace(Gender, which(Gender %in% male), 'Male'),
                                                Gender = replace(Gender, which(Gender %in% female), 'Female'),
                                                Gender = replace(Gender, which(Gender %in% others), 'Others'))

# checking if all values are covered and category is consistent                                                
unique(df_mental_health$Gender)

# age values has some negative values and values over 100
# keeping rows with age between 18 and 100
df_mental_health <- df_mental_health %>% filter(Age >= 18 & Age < 100)

# checking the summary of the Age column
summary(df_mental_health$Age)

# plotting histogram to check the age distribution of the respondents
hist(df_mental_health$Age, 
     xlab = "Respondent's Age", 
     main = "Histogram of Age of Mental Health Survey Respondents", 
     col = "#f89540", xlim = c(0, 100), 
     breaks = c(0, seq(10, 100, 10)), prob = T)

### Which countries and states, maximum respondents are belonging to? With whom are employees more likely to talk about their mental health conditions at workplace?
# top 4 countries on the basis of total count of respondents
top_4_countries_percentage <- (df_mental_health %>%
                                 group_by(Country) %>%
                                 summarise(Percentage = round((n()/nrow(df_mental_health)*100L))) %>%
                                 arrange(desc(Percentage))%>%
                                 head(n=4))

# plotting pie chart for showing percentage of respondents belonging from top 4 countries
plt_pie_top_countries <- (top_4_countries_percentage %>%
                            arrange(-Percentage) %>%
                            mutate(Per_cumsum=cumsum(Percentage)) %>%
                            ggplot(aes(x = "" , y = Percentage, fill = Country)) +
                            geom_col() +
                            geom_text(aes(label = paste(Percentage,"%", sep = "")), 
                                      position = position_stack(vjust = 0.5))+
                            coord_polar("y", start=2) +
                            theme_minimal())

# top 4 states in the US
top_4_states_US <- (df_mental_health %>% 
                      filter(Country == 'United States') %>% 
                      group_by(state) %>% 
                      summarise(Total.Count = n()) %>% 
                      arrange(desc(Total.Count)) %>% 
                      top_n(4))$state

# filtering dataset and keeping records of respondents belonging to top 4 states of the US (on basis of count)
df_top_4_states_US <- df_mental_health %>% filter(state %in% top_4_states_US)

df_MH_top4_pivot <- (df_top_4_states_US %>%
                       select(state, coworkers, supervisor) %>% 
                       pivot_longer(cols = c(coworkers, supervisor), 
                                    names_to = 'Coworker.or.Supervisor', 
                                    values_to = 'Responses'))

df_MH_top4_pivot <- (df_MH_top4_pivot %>% 
                       group_by(state, Coworker.or.Supervisor, Responses) %>% 
                       summarise(Total.Count = n()) %>% 
                       merge(df_top_4_states_US %>% group_by(state) %>% 
                               summarise(Total.State.Count = n()), by = 'state') %>%
                       mutate(Percentage = (Total.Count / Total.State.Count)*100))

plt_al_top_4_states <- (ggplot(df_MH_top4_pivot, 
                               aes(axis1 = state, axis2 = Coworker.or.Supervisor,  
                                   y = Percentage)) +
                          geom_alluvium(aes(fill = Responses)) + 
                          geom_stratum(width = 1/2.7) +
                          geom_text(stat = 'stratum', 
                                    aes(label = after_stat(stratum)), size = 5) + 
                          scale_x_discrete(limits = c("State", "Coworker/Supervisor"), 
                                           expand = c(0.15, 0.05)) + 
                          theme_minimal())

grid.arrange(plt_pie_top_countries, plt_al_top_4_states, ncol = 1)


### How do tech companies fare against non-tech companies in mental health support?
# differentiation of tech vs. non 
tech_companies <- df_mental_health %>%
  filter(tech_company == 'Yes')

notech_companies <- df_mental_health %>%
  filter(tech_company == 'No')

# people seeking treatment
seektreat <- tech_companies %>%
  filter(treatment == 'Yes') %>%
  select(treatment)%>%
  summarise(Percentage = round((n()/nrow(tech_companies))*100L))
seektreat$Type <- 'Treatment'
seektreat$Industry <- 'Tech'

notech_seektreat <- notech_companies %>%
  filter(treatment == 'Yes') %>%
  select(treatment) %>%
  summarise(Percentage = round((n()/nrow(notech_companies))*100L))
notech_seektreat$Type <- 'Treatment'
notech_seektreat$Industry <- 'Non-Tech'

clean_treatmentcomparison <- bind_rows(seektreat, notech_seektreat)

comp_treatment <- ggplot(data=clean_treatmentcomparison,
      aes(x="", y=Percentage, fill=Industry)) +
      geom_bar(stat="identity", position="dodge")+
      xlab("") + ylab("Percentage (%)")+
      theme_minimal()+
      theme(plot.title = element_text(size = 11), axis.title = element_text(size = 9.5), legend.position="none") +
      geom_text(aes(label=paste(Percentage,"%")), position = position_dodge(width = 1), vjust=4, color="white", size=4)+
      ggtitle("Employees Seeking Treatment per Industry")


# types of support
# benefits comparison 
benefit <- tech_companies %>%
  filter(benefits == 'Yes') %>%
  select(benefits)%>%
  summarise(Percentage = round((n()/nrow(tech_companies))*100L))
benefit$Type <- 'Benefits'
benefit$Industry <- 'Tech'

notech_benefit <- notech_companies %>%
  filter(benefits == 'Yes') %>%
  select(benefits) %>%
  summarise(Percentage = round((n()/nrow(notech_companies))*100L))
notech_benefit$Type <- 'Benefits'
notech_benefit$Industry <- 'Non-Tech'

# wellness program comparison
wellness <- tech_companies %>%
  filter(wellness_program == 'Yes') %>%
  select(wellness_program)%>%
  summarise(Percentage = round((n()/nrow(tech_companies))*100L))
wellness$Type <- 'Wellness Programs'
wellness$Industry <- 'Tech'

notech_wellness<- notech_companies %>%
  filter(wellness_program == 'Yes') %>%
  select(wellness_program) %>%
  summarise(Percentage = round((n()/nrow(notech_companies))*100L))
notech_wellness$Type <- 'Wellness Programs'
notech_wellness$Industry <- 'Non-Tech'

# seeking help comparison
s_help <- tech_companies %>%
  filter(seek_help == 'Yes') %>%
  select(seek_help)%>%
  summarise(Percentage = round((n()/nrow(tech_companies))*100L))
s_help$Type <- 'Guidance'
s_help$Industry <- 'Tech'

notech_s_help <- notech_companies %>%
  filter(seek_help == 'Yes') %>%
  select(seek_help)%>%
  summarise(Percentage = round((n()/nrow(notech_companies))*100L))
notech_s_help$Type <- 'Guidance'
notech_s_help$Industry <- 'Non-Tech'

clean_supportcomparison <- bind_rows(s_help, notech_s_help,wellness, notech_wellness, benefit, notech_benefit)
  
comp_all_support <- ggplot(data=clean_supportcomparison,
      aes(x=Type, y=Percentage, fill=Industry)) +
      geom_bar(stat="identity", position="dodge")+
      xlab("") + ylab("Percentage (%)")+
      theme_minimal()+
      theme(plot.title = element_text(size = 11), axis.title = element_text(size = 9.5), legend.position="none") +
      geom_text(aes(label=paste(Percentage,"%")), position = position_dodge(width = 1), vjust=4, color="white", size=2.5)+
      xlab("") + ylab("Percentage (%)")+
      ggtitle("Types of Support Based on Industry")


# sharing with coworkers
coworkers <- tech_companies %>%
  filter(coworkers == 'Yes') %>%
  select(coworkers)%>%
  summarise(Percentage = round((n()/nrow(tech_companies))*100L))
coworkers$Type <- 'Coworkers'
coworkers$Industry <- 'Tech'

notech_coworkers <- notech_companies %>%
  filter(coworkers == 'Yes') %>%
  select(coworkers) %>%
  summarise(Percentage = round((n()/nrow(notech_companies))*100L))
notech_coworkers$Type <- 'Coworkers'
notech_coworkers$Industry <- 'Non-Tech'

# sharing with supervisors
supervisors <- tech_companies %>%
  filter(supervisor == 'Yes') %>%
  select(supervisor)%>%
  summarise(Percentage = round((n()/nrow(tech_companies))*100L))
supervisors$Type <- 'Supervisors'
supervisors$Industry <- 'Tech'

notech_supervisors <- notech_companies %>%
  filter(supervisor == 'Yes') %>%
  select(supervisor) %>%
  summarise(Percentage = round((n()/nrow(notech_companies))*100L))
notech_supervisors$Type <- 'Supervisors'
notech_supervisors$Industry <- 'Non-Tech'

# combine clean data
clean_commcomparison <- bind_rows(coworkers, notech_coworkers, supervisors, notech_supervisors)
  
comp_all_comm <- ggplot(data=clean_commcomparison,
      aes(x=Type, y=Percentage, fill=Industry)) +
      geom_bar(stat="identity", position = "dodge")+
      theme_minimal()+
      theme(plot.title = element_text(size = 11), axis.title = element_text(size = 9.5)) +
      xlab("") + ylab("Percentage (%)")+
      geom_text(aes(label=paste(Percentage,"%")), position = position_dodge(width = 1), vjust=4, color="white", size=2.5)+
      ggtitle("Opinion on Disclosure Based on Industry")


grid.arrange(comp_treatment, arrangeGrob(comp_all_support, comp_all_comm), ncol=2)


### How are the survey responses correlated with each other? What are the factors impacting employees getting treatment for their mental health?
df_MH_copy <- (df_mental_health %>% 
                 select(-c('Timestamp', 'comments', 'no_employees', 'Country', 
                           'mental_vs_physical', 'self_employed', 'remote_work', 
                           'work_interfere', 'state', 'phys_health_consequence', 
                           'mental_health_consequence', 'phys_health_interview', 
                           'mental_health_interview', 'tech_company')) %>% 
                 drop_na() %>% mutate(Gender = as.factor(Gender)))

 for (col in colnames(df_MH_copy)) {
   df_MH_copy[, col] <- as.numeric(df_MH_copy[ ,col])}

corr <- cor(df_MH_copy)
p.mat <- cor_pmat(df_MH_copy)
plt_cor <- ggcorrplot(corr, hc.order = TRUE, type = "lower",
                      p.mat = p.mat, ggtheme = theme_minimal())


correlation_w_treatment <- as.data.frame(round(cor(df_MH_copy ,df_MH_copy$treatment), 2))
row_names <- rownames(correlation_w_treatment)
rownames(correlation_w_treatment) <- NULL
correlation_w_treatment <- cbind(row_names, correlation_w_treatment)
correlation_w_treatment <- correlation_w_treatment[order(-correlation_w_treatment$V1),]
correlation_w_treatment$V1 <- abs(correlation_w_treatment$V1)
correlation_w_treatment <- correlation_w_treatment %>% filter(!row_names == 'treatment')


plt_cor_treatment <- (ggplot(data = correlation_w_treatment, 
                             aes(x = V1, y = row_names, color = row_names, group = row_names)) +
                        geom_segment(data = correlation_w_treatment, 
                                     aes(x = 0, xend = V1, y = row_names,
                                         yend = row_names), size = 1) +
                        geom_point(size = 3) + ggtitle("Correlation with Treatment Variable") + 
                        theme(legend.position = "none") + 
                        xlab("Correlation values") + ylab("Variables") + 
                        theme_minimal() + theme(legend.position = "none",
                                                axis.text = element_text(size = 10),
                                                axis.title = element_text(size = 12)))
grid.arrange(plt_cor, plt_cor_treatment, ncol = 1)

### Does company size play a role in the availability of mental help support for employees?
small <- c("1-5", "6-25","26-100")
large <- c("100-500", "500-1000", "More than 1000")
df_mental_health_copy <- df_mental_health %>%
  mutate(no_employees = as.character(no_employees),
        no_employees = replace(no_employees, which(no_employees %in% small), 'Small'), 
        no_employees = replace(no_employees, which(no_employees %in% large), 'Large'))

small_companies <- df_mental_health_copy %>%
  filter(no_employees == "Small")

large_companies <- df_mental_health_copy %>%
  filter(no_employees == "Large")


#Percentage of Employees per Company Size that Ought Treatment
small_treatY <- small_companies %>%
  filter(treatment == 'Yes') %>%
  summarise(Percentage = round((n()/nrow(small_companies))*100L)) %>%
  mutate(Answer = 'Yes', Size = 'Small')
 
small_treatN <- small_companies %>%
  filter(treatment == 'No') %>%
  summarise(Percentage = round((n()/nrow(small_companies))*100L)) %>%
  mutate(Answer = 'No', Size = 'Small')
    
large_treatY <- large_companies %>%
  filter(treatment == 'Yes') %>%
  summarise(Percentage = round((n()/nrow(large_companies))*100L)) %>%
  mutate(Answer = 'Yes', Size = 'Large')
  
large_treatN <- large_companies %>%
  filter(treatment == 'No') %>%
  summarise(Percentage = round((n()/nrow(large_companies))*100L)) %>%
  mutate(Answer = 'No', Size = 'Large')
  
co_size_treat <- bind_rows(small_treatY, small_treatN, large_treatY, large_treatN)

# label positioning
co_size_treat <- co_size_treat %>%
  group_by(Size) %>%
  mutate(label_y = cumsum(Percentage))

# plotting 
compare_size_treat <- ggplot(co_size_treat,
      aes(x= Size , y=Percentage, fill= Answer)) +
      geom_bar(stat="identity")+
      xlab("Company Size") + ylab("Percentage (%)") +
      theme_minimal()+
      theme(plot.title = element_text(size = 11), axis.title = element_text(size = 9.5)) +
      geom_text(aes(y = label_y, label = paste(Percentage,"%")), vjust = 1.5, colour = "white")+
      ggtitle("Company Size vs. Percentage of People Seeking Treatment")


# comparison of different offerings on the basis of size of the companies

# understanding benefits 
co_size_ben <- df_mental_health %>%
  filter(benefits == 'Yes') %>%
  select(no_employees) %>%
  group_by(no_employees) %>%
  summarise(Total = n())%>%
  mutate(Offering = 'Benefits')
  
# understanding anonymity
co_size_anon <- df_mental_health %>%
  filter(anonymity == 'Yes') %>%
  select(no_employees) %>%
  group_by(no_employees) %>%
  summarise(Total = n())%>%
  mutate(Offering = 'Anonymity')

# understanding whether employers provide resources to seek help
co_size_help <- df_mental_health %>%
  filter(seek_help == 'Yes') %>%
  select(no_employees) %>%
  group_by(no_employees) %>%
  summarise(Total = n()) %>%
  mutate(Offering = 'Guidance to Seek Help')

# understanding wellness programs
co_size_well <- df_mental_health %>%
  filter(wellness_program == 'Yes') %>%
  select(no_employees) %>%
  group_by(no_employees) %>%
  summarise(Total = n()) %>%
  mutate(Offering = 'Wellness Programs')

company_size <- bind_rows(co_size_anon, co_size_ben, co_size_help, co_size_well)

company_sizes <- ggplot(company_size,
      aes(x=no_employees, y=Total, fill=Offering)) +
      geom_bar(stat="identity", position= "dodge")+
      coord_flip() +
      theme_minimal()+
      theme(plot.title = element_text(size = 11), axis.title = element_text(size = 9.5)) +
      ggtitle("Company Size vs. Employees with Access to Resources")+
      xlab("Company Size") + ylab("No. Employees with Accessibility") 

#grid.arrange(compare_size_treat, company_sizes, nrow=2, ncol=1)
compare_size_treat
company_sizes

### Is mental health more stigmatized in companies that do not provide the benefits?
offer_benefits <- df_mental_health %>%
  filter(benefits == "Yes")

nooffer_benefits <- df_mental_health %>%
  filter(benefits == "No")

unknownoffer_benefits <- df_mental_health %>%
  filter(benefits == "Don't know")

#Find Percentage of each for pie chart
percent_offer <- offer_benefits%>%
  summarise(Percentage = round((n()/nrow(df_mental_health))*100L)) %>%
  mutate(Answer = 'Yes')
  
percent_nooffer <- nooffer_benefits %>%
  summarise(Percentage = round((n()/nrow(df_mental_health))*100L)) %>%
  mutate(Answer = 'No')

percent_unknownoffer <- unknownoffer_benefits %>%
  summarise(Percentage = round((n()/nrow(df_mental_health))*100L)) %>%
  mutate(Answer = "Don't know")

benefits_offered <- bind_rows(percent_offer, percent_nooffer, percent_unknownoffer)

comp_benefits_offered <- benefits_offered %>% 
    ggplot(aes(x =Answer, y = Percentage)) +
    geom_col(aes(fill = Answer), color = NA) +
    labs(x = "", y = "Percentage of Answers") +
    geom_text(aes(label = paste(Percentage,"%", sep = "")), 
              position = position_stack(vjust = 0.5), colour = "white", width= 5) +
    coord_polar("y", start=2) + 
    guides(fill = FALSE)

comp_benefits_offered <- benefits_offered %>% 
          mutate(Per_cumsum=cumsum(Percentage)) %>% 
          ggplot(aes(x = "" , y = Percentage, fill = Answer)) +
          geom_col() +
          geom_text(aes(label = paste(Percentage,"%")), 
                    position = position_stack(vjust = 0.5), colour = "white")+
          coord_polar("y", start=2) +
          theme_void() +
          theme(legend.position="none", plot.title = element_text(size = 11)) +
          ggtitle("Does your employer provide mental health benefits?")


# compare observed consequences on the basis of benefits provided
benefit_obs <- offer_benefits %>%
  filter(obs_consequence == 'Yes') %>%
  summarise(Percentage = round((n()/nrow(offer_benefits))*100L)) %>%
  mutate(Benefits = 'Offered')
 
nobenefit_obs <- nooffer_benefits %>%
  filter(obs_consequence == 'Yes') %>%
  summarise(Percentage = round((n()/nrow(nooffer_benefits))*100L)) %>%
  mutate(Benefits = 'Not offered')

unknownbenefit_obs <- unknownoffer_benefits %>%
  filter(obs_consequence == 'Yes') %>%
  summarise(Percentage = round((n()/nrow(unknownoffer_benefits))*100L)) %>%
  mutate(Benefits = 'Unsure if offered')
  
comp_benefits_consq <- bind_rows(benefit_obs, nobenefit_obs, unknownbenefit_obs)


comp_benefits_consq <- comp_benefits_consq %>%
  group_by(Benefits) %>%
  mutate(label_y = cumsum(Percentage))


comparison_consq <- ggplot(comp_benefits_consq,
      aes(x=Benefits, y=Percentage, fill = Benefits)) +
      geom_bar(stat="identity")+
      xlab("")+ ylab("Percentage") +
      theme_minimal()+
      theme(plot.title = element_text(size = 11), axis.text.x = element_text(angle = 45)) +
      geom_text(aes(y = label_y, label = paste(Percentage,"%")), vjust = 1.5, colour = "white") +
      ggtitle("Observed Consequences vs. \nBenefits Offered")

grid.arrange(comp_benefits_offered, comparison_consq, nrow=1, ncol=2)

### Are employees more likely to talk about Mental health or Physical health conditions in an interview?
df_MH_top4_pivot <- df_top_4_states_US %>% 
  select(state, mental_health_interview, phys_health_interview) %>% 
  pivot_longer(cols = c(mental_health_interview, phys_health_interview), 
               names_to = 'Ment.or.Phy.Int', 
               values_to = 'Responses')

df_MH_top4_pivot <- df_MH_top4_pivot %>% 
         group_by(state, Ment.or.Phy.Int, Responses) %>% 
         summarise(Total.Count = n()) %>% 
  merge(df_top_4_states_US %>% group_by(state) %>% summarise(Total.State.Count = n()), by = 'state') %>%
  mutate(Percentage = (Total.Count / Total.State.Count)*100)

ggplot(df_MH_top4_pivot, 
       aes(axis1 = state, axis2 = Ment.or.Phy.Int,  y = Percentage)) +
  geom_alluvium(aes(fill = Responses)) + 
  geom_stratum(width = 1/2.7) +
  geom_text(stat = 'stratum', aes(label = after_stat(stratum)), size = 3) + 
  scale_x_discrete(limits = c("State", "Coworker/Supervisor"), expand = c(0.15, 0.05)) + 
  theme_minimal()

### What is change in attitude of employee and employers on mental health over years? (2014, 2016, 2019)
df_MH_2016 <- read_csv('mental-heath-in-tech-2016_20161114.csv', na = '')
df_MH_2016 <- (df_MH_2016 %>% 
                 rename("seek_help" = "Does your employer offer resources to learn more about mental health concerns and options for seeking help?",
                                      "mental_vs_physical" = "Do you feel that your employer takes mental health as seriously as physical health?",
                                     "treatment" = "Have you ever sought treatment for a mental health issue from a mental health professional?") %>%
                 select(seek_help, mental_vs_physical, treatment) %>%
                 mutate(Timestamp = as.numeric(2016),
                        treatment = replace(treatment, which(treatment == 1), 'Yes'),
                        treatment = replace(treatment, which(treatment == 0), 'No')) %>% drop_na())

df_MH_2019 <- read_csv('mental-heath-in-tech-2019.csv', na = '')
df_MH_2019 <- (df_MH_2019 %>% 
                 rename("seek_help" = "Does your employer offer resources to learn more about mental health disorders and options for seeking help?",
                                     "treatment" = "Have you ever sought treatment for a mental health disorder from a mental health professional?") %>%
                 select(seek_help, treatment) %>%
                 mutate(Timestamp = as.numeric(2019),
                        mental_vs_physical = 'No/NA/Yes',
                        treatment = replace(treatment, which(treatment == 'TRUE'), 'Yes'),
                        treatment = replace(treatment, which(treatment == 'FALSE'), 'No')) %>% drop_na())



df_MH_2014 <- df_mental_health %>% mutate(Timestamp = as.numeric(2014)) %>% select(Timestamp, seek_help, mental_vs_physical, treatment) %>% drop_na()
df_MH_2014_2016 <- rbind(df_MH_2014, df_MH_2016, df_MH_2019)
df_total_responses_201416 <- df_MH_2014_2016 %>% group_by(Timestamp) %>% summarise(Total.Year.Data = n())

plt_skhlp_yes <- (df_MH_2014_2016 %>% group_by(Timestamp, seek_help) %>% 
                    summarise(Total.Count = n()) %>% 
                    merge(df_total_responses_201416, by = 'Timestamp') %>%
                    filter(seek_help %in% c('Yes')) %>% 
                    mutate(Percentage = (Total.Count / Total.Year.Data)*100) %>%
                    ggplot(aes(x = Timestamp, y = Percentage)) + 
                    geom_line(aes(color = seek_help), 
                              position = position_dodge(width = 1), size = 2) + 
                    scale_x_discrete(limits = c(2014, 2016, 2019)) + xlab('Year') + 
                    theme_minimal() + theme(legend.position = "none", 
                                            plot.title = element_text(size = 9),
                                            axis.title = element_text(size = 8),
                                            axis.text = element_text(size = 7)) +
                    ggtitle("Employers Provide\nMental Health Resources?"))

plt_mtvspy_yes <- (df_MH_2014_2016 %>% group_by(Timestamp, mental_vs_physical) %>% 
                     summarise(Total.Count = n()) %>% 
                     merge(df_total_responses_201416, by = 'Timestamp') %>%
                     filter(mental_vs_physical %in% c('Yes')) %>% 
                     mutate(Percentage = (Total.Count / Total.Year.Data)*100) %>%
                     ggplot(aes(x = Timestamp, y = Percentage)) + 
                     geom_line(aes(color = mental_vs_physical), 
                               position = position_dodge(width = 1), size = 2) + 
                     scale_x_discrete(limits = c(2014, 2016)) + xlab('Year') + 
                     theme_minimal()+ theme(legend.position = "none", 
                                            plot.title = element_text(size = 9),
                                            axis.title = element_text(size = 8),
                                            axis.text = element_text(size = 7)) +
                     ggtitle("Take Mental Health As \nSeriously As Physical Health?"))

plt_trt_yes <- (df_MH_2014_2016 %>% group_by(Timestamp, treatment) %>% 
                  summarise(Total.Count = n()) %>% 
                  merge(df_total_responses_201416, by = 'Timestamp') %>%
                  filter(treatment %in% c('Yes')) %>% 
                  mutate(Percentage = (Total.Count / Total.Year.Data)*100) %>%
                  ggplot(aes(x = Timestamp, y = Percentage)) + 
                  geom_line(aes(color = treatment), 
                            position = position_dodge(width = 1), size = 2) + 
                  scale_x_discrete(limits = c(2014, 2016, 2019)) + xlab('Year') + 
                     theme_minimal() + theme(legend.position = "none", 
                                            plot.title = element_text(size = 9),
                                            axis.title = element_text(size = 8),
                                            axis.text = element_text(size = 7)) +
                     ggtitle("Employees Taking Treatment\nFor Mental Health?"))

plt_skhlp <- (df_MH_2014_2016 %>% group_by(Timestamp, seek_help) %>% 
                summarise(Total.Count = n()) %>% 
                merge(df_total_responses_201416, by = 'Timestamp') %>%
                filter(seek_help %in% c('Yes', 'No')) %>%
                mutate(Percentage = (Total.Count / Total.Year.Data)*100) %>%
                ggplot(aes(fill = seek_help, y = Percentage, x = as.factor(Timestamp))) + 
                geom_bar(position = "dodge", stat="identity") + 
                xlab('Year') + 
                theme_minimal() + theme(legend.position = "none",
                                            axis.title = element_text(size = 8),
                                            axis.text = element_text(size = 7)) +
                guides(fill=guide_legend(title="Responses")))


plt_mtvspy <- (df_MH_2014_2016 %>% group_by(Timestamp, mental_vs_physical) %>% 
                 summarise(Total.Count = n()) %>% 
                 merge(df_total_responses_201416, by = 'Timestamp') %>%
                 filter(mental_vs_physical %in% c('Yes', 'No')) %>%
                 mutate(Percentage = (Total.Count / Total.Year.Data)*100) %>%
                 ggplot(aes(fill = mental_vs_physical, y = Percentage, x = Timestamp)) +
                 geom_bar(position = "dodge", stat = "identity") + 
                 scale_x_discrete(limits = c(2014, 2016)) + 
                 xlab('Year') + 
                 theme_minimal() + theme(legend.position = "none",
                                            axis.title = element_text(size = 8),
                                            axis.text = element_text(size = 7)) + 
                 guides(fill=guide_legend(title="Responses"))) 

plt_trt <- (df_MH_2014_2016 %>% group_by(Timestamp, treatment) %>% 
              summarise(Total.Count = n()) %>% 
              merge(df_total_responses_201416, by = 'Timestamp') %>%
              filter(treatment %in% c('Yes', 'No')) %>%
              mutate(Percentage = (Total.Count / Total.Year.Data)*100) %>%
              ggplot(aes(fill = treatment, y = Percentage, x = as.factor(Timestamp))) +
              geom_bar(position = "dodge", stat = "identity") + 
              xlab('Year') + 
              theme_minimal() + theme(axis.title = element_text(size = 7),
                                      axis.text = element_text(size = 6),
                                      legend.title = element_text(size = 8),
                                      legend.text = element_text(size = 8)) + 
              guides(fill=guide_legend(title="Responses")))


grid.arrange(plt_skhlp_yes, plt_mtvspy_yes, plt_trt_yes, plt_skhlp, plt_mtvspy, plt_trt, ncol = 3)


### What were the sentiments of the respondents in the comments?
df_comments <- (df_mental_health %>% 
                  mutate(comments = as.character(comments)) %>%
                  select(Country, Gender, Age, comments))

stop_words_comments <- (df_comments %>%
                          unnest_tokens(word, comments) %>%
                          count(word, sort = TRUE))

tidy_text <- (df_comments %>% drop_na() %>%
                unnest_tokens(output= word, input = comments) %>%
                anti_join(stop_words, by = "word"))

max_words <- (tidy_text %>% 
                count(word, sort = TRUE)%>% 
                mutate(word = reorder(word, n)) %>% slice(1:10))


nrc <- get_sentiments('nrc')
tidy_text_nrc <- (tidy_text %>% inner_join(nrc) %>% count(word, sort = TRUE))

df_sentiments_gender <- (tidy_text %>%
                           inner_join(get_sentiments("bing")) %>%
                           count(Gender, word, sentiment, sort = TRUE) %>%
                           ungroup())

df_sentiment_age <- (tidy_text %>% mutate(Age.Group = case_when(Age>=18 & Age<20 ~ "18-20", 
                                                                Age>=20 & Age<30 ~ "20-30",
                                                                Age>=30 & Age<40 ~ "30-40",
                                                                Age>=40 & Age<50 ~ "40-50",
                                                                Age>=50 & Age<60 ~ "50-60",
                                                                Age>=60 & Age<70 ~ "60-70",
                                                                Age>=70 & Age<80 ~ "70-80",
                                                                Age>=80 & Age<90 ~ "80-90",
                                                                Age>=90 & Age<100 ~ "90+")))

df_sentiment_age <- (df_sentiment_age %>% 
                       inner_join(get_sentiments("bing")) %>%
                       count(Age.Group, word , sentiment, sort = TRUE) %>%
                       ungroup())

plt_max_words <- (ggplot(max_words, aes(n, word)) +
                    geom_col() +
                    labs(y = NULL) + theme_minimal() +
                    ggtitle('Common words in Comments of the Survey'))
  

plt_gender <- (ggplot(df_sentiments_gender, 
                      aes(1737,y= sentiment, fill=Gender)) +
                 geom_col(show.legend = FALSE) +
                 facet_wrap(~Gender, ncol = 2, scales = "free_x") + theme_minimal() +
                 ggtitle('Comments Sentiments by Gender'))

plt_age <- (ggplot(df_sentiment_age, aes(2000,y= sentiment, fill=Age.Group)) +
              geom_col(show.legend = FALSE) +
              facet_wrap(~Age.Group, ncol = 2, scales = "free_x") + theme_minimal() +
              ggtitle('Comments Sentiments by Age Group'))

plt_max_words
plt_gender
plt_age

### What were the most frequently used negative and positive words in the comments?
wordcloud_2 <- (tidy_text %>%
                  inner_join(get_sentiments("bing")) %>%
                  count(word, sentiment, sort = TRUE) %>%
                  acast(word ~ sentiment, value.var = "n", fill = 0) %>%
                  comparison.cloud(colors = c("red", "green"),
                                   max.words = 100))

