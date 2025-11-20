--
-- PostgreSQL database dump
--

\restrict DHLaJlAgxPDZDKygdAdh7KZpezsvKJFSQXWyG8z3IwR41NARvUhUdPGEzgIoADi

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
-- Name: daily_input_table; Type: TABLE; Schema: public; Owner: khein21502
--

CREATE TABLE public.daily_input_table (
    date date NOT NULL,
    is_festival boolean,
    sales integer,
    guests integer,
    staff_count integer,
    assigned_staff text
);


ALTER TABLE public.daily_input_table OWNER TO khein21502;

--
-- Data for Name: daily_input_table; Type: TABLE DATA; Schema: public; Owner: khein21502
--

COPY public.daily_input_table (date, is_festival, sales, guests, staff_count, assigned_staff) FROM stdin;
2025-11-20	f	254000	250	5	Shimizu Keiko, Fujimoto Yui, Matsuda Kenta, Hasegawa Mio, Okada Ren
\.


--
-- Name: daily_input_table daily_input_table_pkey; Type: CONSTRAINT; Schema: public; Owner: khein21502
--

ALTER TABLE ONLY public.daily_input_table
    ADD CONSTRAINT daily_input_table_pkey PRIMARY KEY (date);


--
-- PostgreSQL database dump complete
--

\unrestrict DHLaJlAgxPDZDKygdAdh7KZpezsvKJFSQXWyG8z3IwR41NARvUhUdPGEzgIoADi

