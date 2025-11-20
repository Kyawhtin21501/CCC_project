--
-- PostgreSQL database dump
--

\restrict 2iH98YXSVMI0CQcUfrq9vxbrzafkzrCjT7IVnAPDmEgacrbS7WPHat3cJ4IWSqj

-- Dumped from database version 14.20 (Homebrew)
-- Dumped by pg_dump version 14.20 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: predicted_sales; Type: TABLE; Schema: public; Owner: khein21502
--

CREATE TABLE public.predicted_sales (
    date date NOT NULL,
    predicted_sales numeric
);


ALTER TABLE public.predicted_sales OWNER TO khein21502;

--
-- Name: staff_profile; Type: TABLE; Schema: public; Owner: khein21502
--

CREATE TABLE public.staff_profile (
    id integer NOT NULL,
    name text NOT NULL,
    level integer,
    gender text,
    age integer,
    email text,
    status text
);


ALTER TABLE public.staff_profile OWNER TO khein21502;

--
-- Name: staff_schedule; Type: TABLE; Schema: public; Owner: khein21502
--

CREATE TABLE public.staff_schedule (
    name text,
    morning boolean,
    afternoon boolean,
    night boolean,
    date date NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.staff_schedule OWNER TO khein21502;

--
-- Name: staff_shift; Type: TABLE; Schema: public; Owner: khein21502
--

CREATE TABLE public.staff_shift (
    id integer NOT NULL,
    date date NOT NULL,
    shift character varying(20) NOT NULL,
    name character varying(100),
    level integer
);


ALTER TABLE public.staff_shift OWNER TO khein21502;

--
-- Name: temporary_shift_for_dashboard; Type: TABLE; Schema: public; Owner: khein21502
--

CREATE TABLE public.temporary_shift_for_dashboard (
    id bigint,
    date text,
    shift text,
    name text,
    level bigint
);


ALTER TABLE public.temporary_shift_for_dashboard OWNER TO khein21502;

--
-- Name: user_input; Type: TABLE; Schema: public; Owner: khein21502
--

CREATE TABLE public.user_input (
    date date,
    is_festival boolean,
    sales bigint,
    guests bigint,
    staff_count bigint,
    assigned_staff text
);


ALTER TABLE public.user_input OWNER TO khein21502;

--
-- Name: predicted_sales predicted_sales_pkey; Type: CONSTRAINT; Schema: public; Owner: khein21502
--

ALTER TABLE ONLY public.predicted_sales
    ADD CONSTRAINT predicted_sales_pkey PRIMARY KEY (date);


--
-- Name: staff_profile staff_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: khein21502
--

ALTER TABLE ONLY public.staff_profile
    ADD CONSTRAINT staff_profile_pkey PRIMARY KEY (id);


--
-- Name: staff_schedule staff_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: khein21502
--

ALTER TABLE ONLY public.staff_schedule
    ADD CONSTRAINT staff_schedule_pkey PRIMARY KEY (id, date);


--
-- Name: staff_shift staff_shift_pkey; Type: CONSTRAINT; Schema: public; Owner: khein21502
--

ALTER TABLE ONLY public.staff_shift
    ADD CONSTRAINT staff_shift_pkey PRIMARY KEY (id, date, shift);


--
-- PostgreSQL database dump complete
--

\unrestrict 2iH98YXSVMI0CQcUfrq9vxbrzafkzrCjT7IVnAPDmEgacrbS7WPHat3cJ4IWSqj

