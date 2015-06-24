begin;

drop table if exists ncaa.statistics;

create table ncaa.statistics (
        school_name            		text,
        school_id			integer,
	year		      		integer,
        player_name	      		text,
        player_id	      		integer,
	class_year	      		text,
	season		      		text,
	gp				integer,
	goals				integer,
	gpg				float,
	assists				integer,
	apg				float,
	tp				integer,
	ppg				float,
	min				interval,
	ga				integer,
	gaa				float,
	saves				integer,
	shutouts			integer
);

copy ncaa.statistics from '/tmp/ncaa_statistics.csv' with delimiter as ',' csv header quote as '"';

commit;
