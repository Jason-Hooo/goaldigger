# 檔案：backend/app/models.py

"""

-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.achievements (
  goal_id integer NOT NULL,
  completion_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT achievements_pkey PRIMARY KEY (goal_id),
  CONSTRAINT achievements_goal_id_fkey FOREIGN KEY (goal_id) REFERENCES public.goals(goal_id)
);
CREATE TABLE public.consumption_participants (
  consumption_id integer NOT NULL,
  user_id integer NOT NULL,
  is_payer boolean DEFAULT false,
  shared_amount numeric NOT NULL,
  status character varying DEFAULT 'pending'::character varying,
  CONSTRAINT consumption_participants_pkey PRIMARY KEY (consumption_id, user_id),
  CONSTRAINT consumption_participants_consumption_id_fkey FOREIGN KEY (consumption_id) REFERENCES public.group_consumptions(consumption_id),
  CONSTRAINT consumption_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.expense_types (
  type_id integer NOT NULL DEFAULT nextval('expense_types_type_id_seq'::regclass),
  type_name character varying NOT NULL,
  user_id integer,
  is_expense boolean DEFAULT true,
  CONSTRAINT expense_types_pkey PRIMARY KEY (type_id)
);
CREATE TABLE public.goals (
  goal_id integer NOT NULL DEFAULT nextval('goals_goal_id_seq'::regclass),
  user_id integer NOT NULL,
  goal_name character varying NOT NULL,
  description text,
  target_amount numeric NOT NULL,
  cumulative_amount numeric DEFAULT 0.00,
  deadline date,
  status character varying DEFAULT 'active'::character varying,
  CONSTRAINT goals_pkey PRIMARY KEY (goal_id),
  CONSTRAINT goals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.group_consumptions (
  consumption_id integer NOT NULL DEFAULT nextval('group_consumptions_consumption_id_seq'::regclass),
  group_id integer NOT NULL,
  name character varying NOT NULL,
  amount numeric NOT NULL,
  type_id integer,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT group_consumptions_pkey PRIMARY KEY (consumption_id),
  CONSTRAINT group_consumptions_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups_table(group_id),
  CONSTRAINT group_consumptions_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.expense_types(type_id)
);
CREATE TABLE public.group_members (
  group_id integer NOT NULL,
  user_id integer NOT NULL,
  CONSTRAINT group_members_pkey PRIMARY KEY (group_id, user_id),
  CONSTRAINT group_members_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups_table(group_id),
  CONSTRAINT group_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.groups_table (
  group_id integer NOT NULL DEFAULT nextval('groups_table_group_id_seq'::regclass),
  group_name character varying NOT NULL,
  invitation_code character varying NOT NULL UNIQUE,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT groups_table_pkey PRIMARY KEY (group_id)
);
CREATE TABLE public.personal_consumptions (
  consumption_id integer NOT NULL DEFAULT nextval('personal_consumptions_consumption_id_seq'::regclass),
  user_id integer NOT NULL,
  type_id integer NOT NULL,
  amount numeric NOT NULL,
  description character varying,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  goal_id integer,
  group_consumption_id integer,
  CONSTRAINT personal_consumptions_pkey PRIMARY KEY (consumption_id),
  CONSTRAINT personal_consumptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT personal_consumptions_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.expense_types(type_id),
  CONSTRAINT fk_personal_consumptions_goal FOREIGN KEY (goal_id) REFERENCES public.goals(goal_id),
  CONSTRAINT fk_personal_consumptions_group_consumption FOREIGN KEY (group_consumption_id) REFERENCES public.group_consumptions(consumption_id)
);
CREATE TABLE public.users (
  user_id integer NOT NULL DEFAULT nextval('users_user_id_seq'::regclass),
  name character varying NOT NULL,
  email character varying NOT NULL UNIQUE,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  password character varying,
  CONSTRAINT users_pkey PRIMARY KEY (user_id)
);
"""

