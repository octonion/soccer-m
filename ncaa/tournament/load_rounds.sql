begin;

-- rounds

drop table if exists ncaa.rounds;

create table ncaa.rounds (
	year				integer,
	round_id			integer,
	seed				integer,
	division_id			integer,
	school_id				integer,
	team_name			text,
	bracket				int[],
	p				float,
	primary key (year,round_id,school_id)
);

copy ncaa.rounds from '/tmp/rounds.csv' with delimiter as ',' csv header quote as '"';

drop table if exists ncaa.m;

create table ncaa.m (
       school_id				integer,
       c				float,
       tof				float,
       tdf				float,
       ofd				float,
       dfd				float,
       primary key (school_id)
);

insert into ncaa.m
(school_id,c,tof,tdf,ofd,dfd)
(select
r.school_id as school_id,
exp(i.estimate)*y.exp_factor as c,
hdof.exp_factor*h.offensive as tof,
h.defensive*hddf.exp_factor as tdf,
o.exp_factor as ofd,
d.exp_factor as dfd
from ncaa.rounds r
join ncaa._schedule_factors h
  on (h.year,h.school_id)=(r.year,r.school_id)
join ncaa.schools_divisions hd
  on (hd.year,hd.school_id)=(r.year,r.school_id)
join ncaa._factors hdof
  on (hdof.parameter,hdof.level::integer)=('o_div',hd.div_id)
join ncaa._factors hddf
  on (hddf.parameter,hddf.level::integer)=('d_div',hd.div_id)
join ncaa._factors o
  on (o.parameter,o.level)=('field','offense_home')
join ncaa._factors d
  on (d.parameter,d.level)=('field','defense_home')
join ncaa._factors y
  on (y.parameter,y.level)=('year',r.year::text)
join ncaa._basic_factors i
  on (i.factor)=('(Intercept)')

);

-- matchup probabilities

drop table if exists ncaa.matrix_p;

create table ncaa.matrix_p (
	year				integer,
	field				text,
	school_id				integer,
	opponent_id			integer,
	t_mu				float,
	to_mu				float,
	team_p				float,
	o_mu				float,
	oo_mu				float,
	opponent_p			float,
	primary key (year,field,school_id,opponent_id)
);

insert into ncaa.matrix_p
(year,field,school_id,opponent_id,t_mu,to_mu,o_mu,oo_mu)
(select
r1.year,
'home',
r1.school_id,
r2.school_id,
(m1.c*m1.tof*m1.ofd*m2.tdf) as t_mu,
(10.0/90.0)*(m1.c*m1.tof*m1.ofd*m2.tdf) as to_mu,
(m1.c*m2.tof*m2.dfd*m1.tdf) as o_mu,
(10.0/90.0)*(m1.c*m2.tof*m2.dfd*m1.tdf) as oo_mu
from ncaa.rounds r1
join ncaa.rounds r2
  on ((r2.year)=(r1.year) and not((r2.school_id)=(r1.school_id)))
join ncaa.m m1
  on (m1.school_id)=(r1.school_id)
join ncaa.m m2
  on (m2.school_id)=(r2.school_id)
where
  r1.year=2016
);

insert into ncaa.matrix_p
(year,field,school_id,opponent_id,t_mu,to_mu,o_mu,oo_mu)
(select
r1.year,
'away',
r1.school_id,
r2.school_id,
(m1.c*m1.tof*m1.dfd*m2.tdf) as t_mu,
(10.0/90.0)*(m1.c*m1.tof*m1.dfd*m2.tdf) as to_mu,
(m1.c*m2.tof*m2.ofd*m1.tdf) as o_mu,
(10.0/90.0)*(m1.c*m2.tof*m2.ofd*m1.tdf) as oo_mu
from ncaa.rounds r1
join ncaa.rounds r2
  on ((r2.year)=(r1.year) and not((r2.school_id)=(r1.school_id)))
join ncaa.m m1
  on (m1.school_id)=(r1.school_id)
join ncaa.m m2
  on (m2.school_id)=(r2.school_id)
where
  r1.year=2016
);

insert into ncaa.matrix_p
(year,field,school_id,opponent_id,t_mu,to_mu,o_mu,oo_mu)
(select
r1.year,
'neutral',
r1.school_id,
r2.school_id,
(m1.c*m1.tof*m2.tdf) as t_mu,
(10.0/90.0)*(m1.c*m1.tof*m2.tdf) as to_mu,
(m1.c*m2.tof*m1.tdf) as o_mu,
(10.0/90.0)*(m1.c*m2.tof*m1.tdf) as oo_mu
from ncaa.rounds r1
join ncaa.rounds r2
  on ((r2.year)=(r1.year) and not((r2.school_id)=(r1.school_id)))
join ncaa.m m1
  on (m1.school_id)=(r1.school_id)
join ncaa.m m2
  on (m2.school_id)=(r2.school_id)
where
  r1.year=2016
);

update ncaa.matrix_p
set
team_p=
(skellam(t_mu,o_mu,'win')
+skellam(t_mu,o_mu,'draw')*to_mu/(to_mu+oo_mu)*(1-exp(-to_mu-oo_mu))
+skellam(t_mu,o_mu,'draw')*exp(-to_mu-oo_mu)*to_mu/(to_mu+oo_mu)*(1-exp(-to_mu-oo_mu))
+0.5*skellam(t_mu,o_mu,'draw')*exp(-2*to_mu)*exp(-2*oo_mu)),

opponent_p=
(skellam(t_mu,o_mu,'lose')
+skellam(t_mu,o_mu,'draw')*oo_mu/(to_mu+oo_mu)*(1-exp(-to_mu-oo_mu))
+skellam(t_mu,o_mu,'draw')*exp(-to_mu-oo_mu)*oo_mu/(to_mu+oo_mu)*(1-exp(-to_mu-oo_mu))
+0.5*skellam(t_mu,o_mu,'draw')*exp(-2*to_mu)*exp(-2*oo_mu));

-- Home advantage

drop table if exists ncaa.matrix_field;

create table ncaa.matrix_field (
	year				integer,
	round_id			integer,
	school_id			integer,
	school_seed			integer,
	opponent_id			integer,
	opponent_seed			integer,
	field				text,
	primary key (year,round_id,school_id,opponent_id)
);

insert into ncaa.matrix_field
(year,round_id,school_id,school_seed,opponent_id,opponent_seed,field)
(select
r1.year,
gs.round_id,
r1.school_id,
r1.seed,
r2.school_id,
r2.seed,
'neutral'
from ncaa.rounds r1
join ncaa.rounds r2
  on (r2.year=r1.year and not(r2.school_id=r1.school_id))
join (select generate_series(1, 6) round_id) gs
  on TRUE
where
  r1.year=2016
);

-- 1st round seeds have home

update ncaa.matrix_field
set field='home'
where
    round_id=1
and school_seed is not null;

update ncaa.matrix_field
set field='away'
where
    round_id=1
and opponent_seed is not null;

-- 2nd, 3rd, 4th round higher seeds have home

update ncaa.matrix_field
set field='home'
where year=2016
and round_id in (2,3,4)
and ((school_seed < opponent_seed) or
     (school_seed is not null and opponent_seed is null))
;

update ncaa.matrix_field
set field='away'
where year=2016
and round_id in (2,3,4)
and ((school_seed > opponent_seed) or
     (school_seed is null and opponent_seed is not null))
;

commit;
