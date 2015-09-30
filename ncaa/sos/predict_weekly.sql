begin;

set timezone to 'America/Los_Angeles';

select
g.game_date::date as date,

'home' as site,

g.school_name as team,
'D'||hd.div_id as div,
(exp(i.estimate)*y.exp_factor*hdof.exp_factor*h.offensive*o.exp_factor*v.defensive*vddf.exp_factor)::numeric(4,1) as t_score,

g.opponent_name as opp,
'D'||vd.div_id as div,
(exp(i.estimate)*y.exp_factor*vdof.exp_factor*v.offensive*hddf.exp_factor*h.defensive*d.exp_factor)::numeric(4,1) as o_score

from ncaa.games g
join ncaa._schedule_factors h
  on (h.year,h.school_id)=(g.year,g.school_id)
join ncaa._schedule_factors v
  on (v.year,v.school_id)=(g.year,g.opponent_id)
join ncaa.schools_divisions hd
  on (hd.year,hd.school_id)=(h.year,h.school_id)
join ncaa._factors hdof
  on (hdof.parameter,hdof.level::integer)=('o_div',hd.div_id)
join ncaa._factors hddf
  on (hddf.parameter,hddf.level::integer)=('d_div',hd.div_id)
join ncaa.schools_divisions vd
  on (vd.year,vd.school_id)=(v.year,v.school_id)
join ncaa._factors vdof
  on (vdof.parameter,vdof.level::integer)=('o_div',vd.div_id)
join ncaa._factors vddf
  on (vddf.parameter,vddf.level::integer)=('d_div',vd.div_id)
join ncaa._factors o
  on (o.parameter,o.level)=('field','offense_home')
join ncaa._factors d
  on (d.parameter,d.level)=('field','defense_home')
join ncaa._factors y
  on (y.parameter,y.level)=('year',g.year::text)
join ncaa._basic_factors i
  on (i.factor)=('(Intercept)')
where
not(g.game_date='')
and g.game_date::date between current_date and current_date+6
and g.location='Home'

union

select

g.game_date::date as date,

'neutral' as site,

g.school_name as team,
'D'||hd.div_id as div,
(exp(i.estimate)*y.exp_factor*hdof.exp_factor*h.offensive*v.defensive*vddf.exp_factor)::numeric(4,1) as t_score,

g.opponent_name as opp,
'D'||vd.div_id as div,
(exp(i.estimate)*y.exp_factor*vdof.exp_factor*v.offensive*hddf.exp_factor*h.defensive)::numeric(4,1) as o_score

from ncaa.games g
join ncaa._schedule_factors h
  on (h.year,h.school_id)=(g.year,g.school_id)
join ncaa._schedule_factors v
  on (v.year,v.school_id)=(g.year,g.opponent_id)
join ncaa.schools_divisions hd
  on (hd.year,hd.school_id)=(h.year,h.school_id)
join ncaa._factors hdof
  on (hdof.parameter,hdof.level::integer)=('o_div',hd.div_id)
join ncaa._factors hddf
  on (hddf.parameter,hddf.level::integer)=('d_div',hd.div_id)
join ncaa.schools_divisions vd
  on (vd.year,vd.school_id)=(v.year,v.school_id)
join ncaa._factors vdof
  on (vdof.parameter,vdof.level::integer)=('o_div',vd.div_id)
join ncaa._factors vddf
  on (vddf.parameter,vddf.level::integer)=('d_div',vd.div_id)
join ncaa._factors y
  on (y.parameter,y.level)=('year',g.year::text)
join ncaa._basic_factors i
  on (i.factor)=('(Intercept)')
where
not(g.game_date='')

and g.game_date::date between current_date and current_date+6

and g.location='Neutral'
order by team asc, date asc;

copy
(
select
g.game_date::date as date,

'home' as site,

g.school_name as team,
'D'||hd.div_id as div,
(exp(i.estimate)*y.exp_factor*hdof.exp_factor*h.offensive*o.exp_factor*v.defensive*vddf.exp_factor)::numeric(4,1) as t_score,

g.opponent_name as opp,
'D'||vd.div_id as div,
(exp(i.estimate)*y.exp_factor*vdof.exp_factor*v.offensive*hddf.exp_factor*h.defensive*d.exp_factor)::numeric(4,1) as o_score

from ncaa.games g
join ncaa._schedule_factors h
  on (h.year,h.school_id)=(g.year,g.school_id)
join ncaa._schedule_factors v
  on (v.year,v.school_id)=(g.year,g.opponent_id)
join ncaa.schools_divisions hd
  on (hd.year,hd.school_id)=(h.year,h.school_id)
join ncaa._factors hdof
  on (hdof.parameter,hdof.level::integer)=('o_div',hd.div_id)
join ncaa._factors hddf
  on (hddf.parameter,hddf.level::integer)=('d_div',hd.div_id)
join ncaa.schools_divisions vd
  on (vd.year,vd.school_id)=(v.year,v.school_id)
join ncaa._factors vdof
  on (vdof.parameter,vdof.level::integer)=('o_div',vd.div_id)
join ncaa._factors vddf
  on (vddf.parameter,vddf.level::integer)=('d_div',vd.div_id)
join ncaa._factors o
  on (o.parameter,o.level)=('field','offense_home')
join ncaa._factors d
  on (d.parameter,d.level)=('field','defense_home')
join ncaa._factors y
  on (y.parameter,y.level)=('year',g.year::text)
join ncaa._basic_factors i
  on (i.factor)=('(Intercept)')
where
not(g.game_date='')

and g.game_date::date between current_date and current_date+6

and g.location='Home'
union
select

g.game_date::date as date,

'neutral' as site,

g.school_name as team,
'D'||hd.div_id as div,
(exp(i.estimate)*y.exp_factor*hdof.exp_factor*h.offensive*v.defensive*vddf.exp_factor)::numeric(4,1) as t_score,

g.opponent_name as opp,
'D'||vd.div_id as div,
(exp(i.estimate)*y.exp_factor*vdof.exp_factor*v.offensive*hddf.exp_factor*h.defensive)::numeric(4,1) as o_score

from ncaa.games g
join ncaa._schedule_factors h
  on (h.year,h.school_id)=(g.year,g.school_id)
join ncaa._schedule_factors v
  on (v.year,v.school_id)=(g.year,g.opponent_id)
join ncaa.schools_divisions hd
  on (hd.year,hd.school_id)=(h.year,h.school_id)
join ncaa._factors hdof
  on (hdof.parameter,hdof.level::integer)=('o_div',hd.div_id)
join ncaa._factors hddf
  on (hddf.parameter,hddf.level::integer)=('d_div',hd.div_id)
join ncaa.schools_divisions vd
  on (vd.year,vd.school_id)=(v.year,v.school_id)
join ncaa._factors vdof
  on (vdof.parameter,vdof.level::integer)=('o_div',vd.div_id)
join ncaa._factors vddf
  on (vddf.parameter,vddf.level::integer)=('d_div',vd.div_id)
join ncaa._factors y
  on (y.parameter,y.level)=('year',g.year::text)
join ncaa._basic_factors i
  on (i.factor)=('(Intercept)')
where
not(g.game_date='')

and g.game_date::date between current_date and current_date+6

and g.location='Neutral'
order by team asc, date asc
) to '/tmp/predict_weekly.csv' csv header;

commit;
