begin;

drop table if exists ncaa_pbp.team_summaries;

create table ncaa_pbp.team_summaries (
       year					integer,
       year_id					integer,
       division_id				integer,
       team_id					integer,
       team_name				text,
       jersey_number				text,
       player_name				text,
       class_year				text,
       gp					integer,
       gs					integer,
       goals					integer,
       assists					float,
       points					float,
       sh_att					integer,
       fouls					integer,
       red_cards				integer,
       yellow_cards				integer,
       gc					integer,
       goal_app					integer,
       ggs					integer,
       goalie_min_played			text,
       ga					integer,
       gaa					float,
       saves					float,
       save_pct					float,
       shutouts					integer,
       g_wins					integer,
       g_loss					integer,
       d_saves					integer,
       corners					integer,
       ps					integer,
       psa					integer,
       gwg					integer,
       primary key (year_id,team_id,player_name),
       unique (year,team_id,player_name)
);

copy ncaa_pbp.team_summaries from '/tmp/team_summaries.csv' with delimiter as E'\t' csv;

commit;
