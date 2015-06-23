begin;

drop table if exists ncaa_pbp.player_summaries;

create table ncaa_pbp.player_summaries (
       year					integer,
       year_id					integer,
       division_id				integer,
       team_id					integer,
       team_name				text,
       jersey_number				text,
       player_id				integer,
       player_name				text,
       player_url				text,
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
       primary key (year_id, player_id),
       unique (year, player_id)
);

copy ncaa_pbp.player_summaries from '/tmp/player_summaries.csv' with delimiter as E'\t' csv;

commit;
