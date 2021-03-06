sink("diagnostics/lmer.txt")

library(lme4)
#library("nortest")
library(RPostgreSQL)

#library("sp")

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv,host="localhost",port="5432",dbname="soccer-m")

query <- dbSendQuery(con, "
select
distinct
r.game_id,
r.year,
r.field as field,
r.school_id as team,
r.team_div_id as o_div,
r.opponent_id as opponent,
r.opponent_div_id as d_div,
r.game_length as game_length,

(case
  when r.game_length='0 OT' then r.team_score
  else least(r.team_score,r.opponent_score)
end) as gs,

(case
  when r.game_length='0 OT' then 1.0
  when r.game_length='1 OT' and not(r.team_score=r.opponent_score)
    then 1.0
  when r.game_length='1 OT' and (r.team_score=r.opponent_score)
    then 10.0/9.0
  when r.game_length='2 OT' and not(r.team_score=r.opponent_score)
    then 10.0/9.0
  when r.game_length='2 OT' and (r.team_score=r.opponent_score)
    then 11.0/9.0
  when r.game_length in ('3 OT','4 OT','5 OT') then 1.0
end) as w

from ncaa.results r

where
    r.year between 2012 and 2020

and r.team_div_id is not null
and r.opponent_div_id is not null

--and r.team_div_id=1
--and r.opponent_div_id=1

-- fit all excluding November and December

--and not(extract(month from r.game_date) in (11,12))
;")

games <- fetch(query,n=-1)

dim(games)

attach(games)

pll <- list()

# Fixed parameters

year <- as.factor(year)
#contrasts(year)<-'contr.sum'

field <- as.factor(field)
field <- relevel(field, ref = "neutral")

d_div <- as.factor(d_div)

o_div <- as.factor(o_div)

#game_length <- as.factor(game_length)

#fp <- data.frame(year,field,d_div,o_div,game_length)

fp <- data.frame(year,field,d_div,o_div)
fpn <- names(fp)

# Random parameters

game_id <- as.factor(game_id)
#contrasts(game_id) <- 'contr.sum'

offense <- as.factor(paste(year,"/",team,sep=""))
#contrasts(offense) <- 'contr.sum'

defense <- as.factor(paste(year,"/",opponent,sep=""))
#contrasts(defense) <- 'contr.sum'

rp <- data.frame(offense,defense)
rpn <- names(rp)

for (n in fpn) {
  df <- fp[[n]]
  level <- as.matrix(attributes(df)$levels)
  parameter <- rep(n,nrow(level))
  type <- rep("fixed",nrow(level))
  pll <- c(pll,list(data.frame(parameter,type,level)))
}

for (n in rpn) {
  df <- rp[[n]]
  level <- as.matrix(attributes(df)$levels)
  parameter <- rep(n,nrow(level))
  type <- rep("random",nrow(level))
  pll <- c(pll,list(data.frame(parameter,type,level)))
}

# Model parameters

parameter_levels <- as.data.frame(do.call("rbind",pll))
dbWriteTable(con,c("ncaa","_parameter_levels"),parameter_levels,row.names=TRUE)

g <- cbind(fp,rp)

g$w <- games$w

dim(g)

model <- gs ~ year+field+d_div+o_div+(1|offense)+(1|defense)+(1|game_id)

fit <- glmer(model, data=g, verbose=TRUE, family=poisson(link=log), weights=w,
             nAGQ=0,
	     control=glmerControl(optimizer = "nloptwrap"))
#            control=glmerControl(optimizer="bobyqa"))

fit
summary(fit)

# List of data frames

# Fixed factors

f <- fixef(fit)
fn <- names(f)

# Random factors

r <- ranef(fit)
rn <- names(r) 

results <- list()

for (n in fn) {

  df <- f[[n]]

  factor <- n
  level <- n
  type <- "fixed"
  estimate <- df

  results <- c(results,list(data.frame(factor,type,level,estimate)))

 }

for (n in rn) {

  df <- r[[n]]

  factor <- rep(n,nrow(df))
  type <- rep("random",nrow(df))
  level <- row.names(df)
  estimate <- df[,1]

  results <- c(results,list(data.frame(factor,type,level,estimate)))

 }

combined <- as.data.frame(do.call("rbind",results))

dbWriteTable(con,c("ncaa","_basic_factors"),as.data.frame(combined),row.names=TRUE)

quit("no")
