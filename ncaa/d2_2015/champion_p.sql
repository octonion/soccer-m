begin;

select
r.team_name,p::numeric(4,3)
from ncaa.rounds r
join ncaa.schools t
  on (t.school_id)=(r.school_id)
where round_id=3
order by p desc;

copy
(
select
r.team_name,p::numeric(4,3)
from ncaa.rounds r
join ncaa.schools t
  on (t.school_id)=(r.school_id)
where round_id=3
order by p desc
) to '/tmp/champion_p.csv' csv header;

commit;
