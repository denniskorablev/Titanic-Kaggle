# Based on Tutorial of Trevor Stephens http://trevorstephens.com/
# Re-writed by Dennis Lyubyvy 

# Set working directory and import datafiles
setwd("~/github/Titanic-Kaggle/")
train <- read.csv("train.csv")
test <- read.csv("test.csv")
history <- {}
history <- read.csv("history.csv")
history <- history[,-1]
CR_max <- 0
    #read.csv("CR_max.csv")


# Install and load required packages for decision trees and forests
library(rpart)
#install.packages('randomForest')
library(randomForest)
#install.packages('party')
library(party)

# Join together the test and train sets for easier feature engineering
test$Survived <- NA
combi <- rbind(train, test)

# Convert to a string
combi$Name <- as.character(combi$Name)

# Engineered variable: Title
combi$Title <- sapply(combi$Name, FUN=function(x) {strsplit(x, split='[,.]')[[1]][2]})
combi$Title <- sub(' ', '', combi$Title)
# Combine small title groups
combi$Title[combi$Title %in% c('Mme', 'Mlle')] <- 'Mlle'
combi$Title[combi$Title %in% c('Capt', 'Don', 'Major', 'Sir')] <- 'Sir'
combi$Title[combi$Title %in% c('Dona', 'Lady', 'the Countess', 'Jonkheer')] <- 'Lady'
# Convert to a factor
combi$Title <- factor(combi$Title)

# Engineered variable: Family size
combi$FamilySize <- combi$SibSp + combi$Parch + 1

# Engineered variable: Family
combi$Surname <- sapply(combi$Name, FUN=function(x) {strsplit(x, split='[,.]')[[1]][1]})
combi$FamilyID <- paste(as.character(combi$FamilySize), combi$Surname, sep="")
combi$FamilyID[combi$FamilySize <= 2] <- 'Small'
# Delete erroneous family IDs
famIDs <- data.frame(table(combi$FamilyID))
famIDs <- famIDs[famIDs$Freq <= 2,]
combi$FamilyID[combi$FamilyID %in% famIDs$Var1] <- 'Small'
# Convert to a factor
combi$FamilyID <- factor(combi$FamilyID)

#calculate Fare per person

for (t in unique(combi$Ticket)) {
    who <- which(combi$Ticket==t)
    combi$Fare2[who] <- combi$Fare[who[1]]/length(who)
}

# Fill in Age NAs
summary(combi$Age)
Agefit <- rpart(Age ~ Pclass + Sex + SibSp + Parch 
                #+ Fare + Fare2
                + Embarked + Title + FamilySize, 
                data=combi[!is.na(combi$Age),], method="anova")

combi$Age[is.na(combi$Age)] <- predict(Agefit, combi[is.na(combi$Age),])

# Check what else might be missing
summary(combi)
# Fill in Embarked blanks
summary(combi$Embarked)
which(combi$Embarked == '')
combi$Embarked[c(62,830)] = "S"
#combi$Embarked[c(62,830)] = "C"
combi$Embarked <- factor(combi$Embarked)


# Fill in Fare NAs
summary(combi$Fare)
which(is.na(combi$Fare))
#combi$Fare[1044] <- median(combi$Fare[which(combi$Pclass==3)], na.rm=TRUE)
combi$Fare[1044] <- median(combi$Fare, na.rm=TRUE)
#log Age (Dennis)
combi$Log_Age <- log(combi$Age)


combi$Ticket2 <- substr(gsub("[][!#$%()*,.:;<=>@^_`|~.{} ]", "", as.character(combi$Ticket)), 1, 1)
combi$Ticket2 <- as.factor(combi$Ticket2)


# New factor for Random Forests, only allowed <32 levels, so reduce number
combi$FamilyID2 <- combi$FamilyID
# Convert back to string
combi$FamilyID2 <- as.character(combi$FamilyID2)
combi$FamilyID2[combi$FamilySize <= 3] <- 'Small'
# And convert back to factor
combi$FamilyID2 <- factor(combi$FamilyID2)
#combi$Ticket <- as.factor(combi$Ticket)

# Sector
combi$Sector <- substr(combi$Cabin, 1, 1)
#combi$Sector[combi$Sector==''] <- ''

#table(combi$Sector)
#Sectorfit <- rpart(Sector ~ Pclass + Sex + Age + SibSp + Parch + Fare2 + Fare + Embarked + Title + FamilySize + Ticket2, 
                data=combi[which(combi$Sector!=''),], method="anova")

#combi$Sector[which(combi$Sector=='')] <- predict(Sectorfit, combi[which(combi$Sector==''),])
combi$Sector <- as.factor(combi$Sector)
table(combi$Sector)

#combi$Pclass <- as.factor(combi$Pclass)

#################### PCA ####################
combi_pca <- combi
str(combi_pca)
#combi_pca$Survived <- as.numeric(combi_pca$Survived)
combi_pca$Sex <- as.numeric(combi_pca$Sex)
#combi_pca$Age <- as.numberic(combi_pca$Sex)
#combi_pca$SibSp <- as.numberic(combi_pca$Sex)
#combi_pca$Parch <- as.numberic(combi_pca$Parch)
#combi_pca$Fare2 <- as.numberic(combi_pca$Fare2)
combi_pca$Embarked <- as.numeric(combi_pca$Embarked)
#combi_pca$Title  <- as.numeric(combi_pca$Title)
#Title
combi_pca$Col <- 0
combi_pca$Col[which(combi_pca$Title=='Col')] <- 1

combi_pca$Dr <- 0
combi_pca$Dr[which(combi_pca$Title=='Dr')] <- 1

combi_pca$Lady <- 0
combi_pca$Lady[which(combi_pca$Title=='Lady')] <- 1

combi_pca$Master <- 0
combi_pca$Master[which(combi_pca$Title=='Master')] <- 1

combi_pca$Miss <- 0
combi_pca$Miss[which(combi_pca$Title=='Miss')] <- 1

combi_pca$Mlle <- 0
combi_pca$Mlle[which(combi_pca$Title=='Mlle')] <- 1

combi_pca$Mr <- 0
combi_pca$Mr[which(combi_pca$Title=='Mr')] <- 1

combi_pca$Ms <- 0
combi_pca$Ms[which(combi_pca$Title=='Ms')] <- 1

combi_pca$Rev <- 0
combi_pca$Rev[which(combi_pca$Title=='Rev')] <- 1

combi_pca$Sir <- 0
combi_pca$Sir[which(combi_pca$Title=='Sir')] <- 1

combi_pca$Mrs <- 0
combi_pca$Mrs[which(combi_pca$Title=='Mrs')] <- 1


combi_pca$FamilySize  <- as.numeric(combi_pca$FamilySize)
combi_pca$FamilyID  <- as.numeric(combi_pca$FamilyID)
combi_pca$FamilyID2  <- as.numeric(combi_pca$FamilyID2)
combi_pca$Sector <- as.numeric(combi_pca$Sector)

combi_pca <- combi_pca[,-which(names(combi_pca) %in% c('PassengerId',
                                                       'Survived',
                                                       'Name','Ticket','Cabin','Title','Surname','Ticket2','FamilyID2'))]
str(combi_pca)
head(combi_pca)
which(is.na(combi_pca))

# #Lasso
# x <- as.matrix(combi_pca[1:1309,-1])
# y <- combi_pca$Survived
# y.test <- y[892:1309]
# library(glmnet)
# grid=10^seq(10,-2,length=100)
# ridge.mod=glmnet(x[892:1309,],y[892:1309],alpha=0,lambda=grid)
# cv.out=cv.glmnet(x[1:891,],y[1:891],alpha=0)
# plot(cv.out)
# bestlam=cv.out$lambda.min
# bestlam
# ridge.pred=predict(ridge.mod,s=bestlam ,newx=x[892:1309,])
# mean((ridge.pred-y.test)^2)




combi_pca.scaled <- data.frame(apply(combi_pca, 2, scale))


#combi_pca <- scale(combi_pca,center = T,scale = T)
combi.pr <- prcomp(~ ., data=combi_pca, na.action=na.omit, scale=TRUE)

plot(combi.pr)
dim(combi.pr$x)
summary(combi.pr)
pc.use <- 5
trunc <- combi.pr$x[,1:pc.use] %*% t(combi.pr$rotation[,1:pc.use])
combi$PCA1 <- trunc[,1]
combi$PCA2 <- trunc[,2]
combi$PCA3 <- trunc[,3]
combi$PCA4 <- trunc[,4]
combi$PCA5 <- trunc[,5]

#RANDOM FORESTS

# Split back into test and train sets
train <- combi[1:891,]
test <- combi[892:1309,]

# Build Random Forest Ensemble
#set.seed(415)
#fit <- randomForest(as.factor(Survived) ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked + Title + FamilySize + FamilyID2 + Age_Pclass,
#                    data=train, importance=TRUE, ntree=2000)
# Look at variable importance
#varImpPlot(fit)
# Now let's make a prediction and write a submission file
#Prediction <- predict(fit, test)
#submit <- data.frame(PassengerId = test$PassengerId, Survived = Prediction)
#write.csv(submit, file = "firstforest.csv", row.names = FALSE)

# CV for Random Forest
CV_CR <- function(k) { 
n <- dim(train)[1]
fold <- {}
train_fold <- {}
fold[1] <- 0
CR <- {}

for (i in 1:k) {
    fold[i+1] <- round(n*i/k)
    train_fold[i] <- list((fold[i]+1):fold[i+1])
    train_fold_data <- train[train_fold[[i]],]

    fit <- cforest(as.factor(Survived) ~ 
                       Pclass
                       + Sex 
                       + (Age^2 * Pclass * Sex)
                       + SibSp
                       + Parch 
                       + Fare2
                       + Embarked
                       + Title  
                       +FamilySize + 
                       FamilyID +
                       + Sector
#                   + Log_Age
                     + Ticket2
#                      + PCA1
                     #  + PCA2
#+ PCA3
#+ PCA4
#+ PCA5
,data = train_fold_data, controls=cforest_unbiased(ntree=2000, mtry=3))

train_pred <- predict(fit, train_fold_data, OOB=TRUE, type = "response")
CR[i] <- sum(train_pred==train_fold_data$Survived)/length(train_pred)
print(CR[i])
}
return(mean(CR))
}
CR <- CV_CR(5)
cat('Correctness rate:',CR)
if (CR_max<CR) {
    CR_max=CR
    cat("You've got new best results!!! :",CR)
    write.csv(CR_max, file = "CR_max.csv", row.names = TRUE)
}




#build train tree and test prediction 
fit <- cforest(as.factor(Survived) ~ 
                   Pclass
               + Sex 
               + Age
               + SibSp
               + Parch 
               + Fare2
               + Embarked
               + Title  
               +FamilySize + 
                   FamilyID +
                   + Sector
               #                   + Log_Age
               + Ticket2
               #                      + PCA1
               #  + PCA2
               #+ PCA3
               #+ PCA4
               #+ PCA5
               ,data = train, controls=cforest_unbiased(ntree=2000, mtry=3))

# Now let's make a prediction and write a submission file
Prediction <- predict(fit, test, OOB=TRUE, type = "response")
submit <- data.frame(PassengerId = test$PassengerId, Survived = Prediction)
write.csv(submit, file = "forest.csv", row.names = FALSE)
Prediction_list <- as.numeric(levels(Prediction))[Prediction]

#rm(history)
#history <- {}
history$histmean <- as.numeric(Prediction)
history <- as.data.frame(history)
history <- cbind(history,as.numeric(Prediction))
timestamp <- round(proc.time()[3])
colnames(history)[dim(history)[2]] <- timestamp
colnames(history)[1] <- 'histmean'
history$histmean <- rowMeans(history[,-1])
write.csv(history, file = "history.csv", row.names = TRUE)
head(history)
# CHECK


is.last.different <- function() {
    z <- dim(history)[2]
    last <- history[,z]
    for (i in 2:z-1) {
        if (all(history[,i]==last)) {
            cat('it was done before, sorry',names(history)[i+1])
        }
    }
    
    
}

is.last.different()

print('difference:')
print(history[which(history[,1]!=round(history[,1])),])
print(combi[which(history[,1]!=round(history[,1])),])
