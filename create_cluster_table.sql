--drop cluster my_cluster

CREATE CLUSTER my_cluster ( fd_date date, fc_id char(3) );

-- drop table my_table;
-- Create table
create table my_table
(
  fd_date date,
  fc_id   char(3),
  fn_val1 number(13,2),
  fn_val2 number(13,2)
)
cluster my_cluster (fd_date, fc_id);

-- Create/Recreate primary, unique and foreign key constraints 
alter table my_table
  add constraint pk_my_table primary key (FD_DATE, FC_ID);

CREATE INDEX my_cluster_index
   ON CLUSTER my_cluster;
