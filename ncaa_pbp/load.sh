#!/bin/bash

cmd="psql template1 --tuples-only --command \"select count(*) from pg_database where datname = 'soccer-m';\""

db_exists=`eval $cmd`
 
if [ $db_exists -eq 0 ] ; then
   cmd="createdb soccer-m"
   eval $cmd
fi

psql soccer-m -f schema/create_schema.sql

# Years with data

cp csv/ncaa_years.csv /tmp/years.csv
psql soccer-m -f loaders/load_years.sql
rm /tmp/years.csv

# Divisions by year with data

cp csv/ncaa_years_divisions.csv /tmp/years_divisions.csv
psql soccer-m -f loaders/load_years_divisions.sql
rm /tmp/years_divisions.csv

# Teams

tail -q -n+2 csv/ncaa_teams_2*.csv >> /tmp/teams.csv
psql soccer-m -f loaders/load_teams.sql
rm /tmp/teams.csv

# Team schedules

tail -q -n+2 csv/ncaa_team_schedules_*.csv >> /tmp/schedules.csv
psql soccer-m -f loaders/load_schedules.sql
rm /tmp/schedules.csv

# Rosters

tail -q -n+2 csv/ncaa_team_rosters_*.csv >> /tmp/rosters.csv
rpl -e '\t--\t' '\t\t' /tmp/rosters.csv
rpl -e '\t-\t' '\t\t' /tmp/rosters.csv
psql soccer-m -f loaders/load_rosters.sql
rm /tmp/rosters.csv

# Boxscores

cp csv/ncaa_boxscores_201[567]*.csv.gz /tmp
gzip -d /tmp/ncaa_boxscores_*.csv.gz
#tail -q -n+2 csv/ncaa_boxscores_*.csv >> /tmp/boxscores.csv
tail -q -n+2 /tmp/ncaa_boxscores_*.csv >> /tmp/boxscores.csv
psql soccer-m -f loaders/load_boxscores.sql
rm /tmp/boxscores.csv
rm /tmp/ncaa_boxscores_*.csv

# Player summaries

tail -q -n+2 csv/ncaa_player_summaries_*.csv >> /tmp/player_summaries.csv
rpl -q '""' '' /tmp/player_summaries.csv
rpl -q ' ' '' /tmp/player_summaries.csv
psql soccer-m -f loaders/load_player_summaries.sql
rm /tmp/player_summaries.csv

# Team summaries

tail -q -n+2 csv/ncaa_team_summaries_*.csv >> /tmp/team_summaries.csv
rpl -e '\t-\t' '\t\t' /tmp/team_summaries.csv
rpl -e '\t-\t' '\t\t' /tmp/team_summaries.csv
rpl -q '""' '' /tmp/team_summaries.csv
rpl -q ' ' '' /tmp/team_summaries.csv
psql soccer-m -f loaders/load_team_summaries.sql
rm /tmp/team_summaries.csv

# Remove commas from some columns, convert to integer

#psql soccer-m -f cleaning/commas_psp.sql
#psql soccer-m -f cleaning/commas_tsh.sql
#psql soccer-m -f cleaning/commas_tsp.sql
#psql soccer-m -f cleaning/commas_tsf.sql

# Game periods

tail -q -n+2 csv/ncaa_games_periods_*.csv >> /tmp/periods.csv
rpl "[" "{" /tmp/periods.csv
rpl "]" "}" /tmp/periods.csv
psql soccer-m -f loaders/load_periods.sql
rm /tmp/periods.csv

# Load play_by_play data

cp csv/ncaa_games_play_by_play_*.csv.gz /tmp
gzip -d /tmp/ncaa_games_play_by_play_*.csv.gz
tail -q -n+2 /tmp/ncaa_games_play_by_play_*.csv >> /tmp/play_by_play.csv
#tail -q -n+2 csv/ncaa_games_play_by_play_*.csv >> /tmp/play_by_play.csv
psql soccer-m -f loaders/load_play_by_play.sql
rm /tmp/play_by_play.csv
rm /tmp/ncaa_games_play_by_play_*.csv

# Remove duplicate rows

#psql soccer-m -f cleaning/deduplicate_periods.sql
#psql soccer-m -f cleaning/deduplicate_pbp.sql
#psql soccer-m -f cleaning/deduplicate_bsh.sql
#psql soccer-m -f cleaning/deduplicate_bsp.sql
#psql soccer-m -f cleaning/deduplicate_bsf.sql

# Add primary keys and constraints

#psql soccer-m -f cleaning/add_pk_periods.sql
#psql soccer-m -f cleaning/add_pk_pbp.sql
#psql soccer-m -f cleaning/add_pk_bsh.sql
#psql soccer-m -f cleaning/add_pk_bsp.sql
#psql soccer-m -f cleaning/add_pk_bsf.sql
