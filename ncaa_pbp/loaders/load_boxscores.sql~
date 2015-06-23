begin;

drop table if exists ncaa_pbp.boxscores;

create table ncaa_pbp.boxscores (
       game_id					integer,
       section_id				integer,
       player_id				integer,
       player_name				text,
       player_url				text,
       position					text,
       goals					integer,
       assists					float,
       sh_att					integer,
       sog					integer,
       fouls					integer,
       red_cards				integer,
       yellow_cards				integer,
       gc					integer,
       goal_app					integer,
       ggs					integer,
       goalie_min_plyd				text,
       ga					integer,
       saves					float,
       shutouts					integer,
       g_wins					integer,
       g_loss					integer,
       dsaves					integer,
       corners					integer

-- This will fail if the two teams are in different divisions
-- Best fix?
--       primary key (game_id, section_id, player_name, position)
);

copy ncaa_pbp.boxscores from '/tmp/boxscores.csv' with delimiter as E'\t' csv;

commit;
