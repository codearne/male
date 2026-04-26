--
-- PostgreSQL database dump
--

\restrict xB13m2yKqRTRvbLOvtfBckUn0zBc2uTGHxdhiIC6mvo4Z6YSSvdh9Q69QsJtAc5

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-04-26 15:03:35

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5 (class 2615 OID 16622)
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- TOC entry 262 (class 1255 OID 25062)
-- Name: f_klubiparimad(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_klubiparimad(klubi_id integer) RETURNS TABLE(mangija text, elo integer)
    LANGUAGE plpgsql
    AS $$
    BEGIN
RETURN query 
SELECT (eesnimi || ' ' || perenimi)::text, ranking 
FROM isikud
where klubis = klubi_id
order by ranking desc LIMIT 3;
END;
$$;


--
-- TOC entry 248 (class 1255 OID 24654)
-- Name: f_klubiranking(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_klubiranking(klubi_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
declare keskmine numeric;
    BEGIN
select round(avg(ranking), 1)
into keskmine
from isikud join klubid on isikud.klubis = klubid.id
WHERE klubid.id = klubi_id;
        RETURN keskmine;
    END;
$$;


--
-- TOC entry 249 (class 1255 OID 25055)
-- Name: f_top10(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_top10(turniiri_id integer) RETURNS TABLE(mangija text, punkte numeric)
    LANGUAGE plpgsql
    AS $$
    BEGIN
RETURN query SELECT v.mangija, v.punkte FROM v_edetabelid v 
where v.turniir = turniiri_id
order by punkte desc LIMIT 10;
END;
$$;


--
-- TOC entry 247 (class 1255 OID 24653)
-- Name: f_vanus(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_vanus(synnikuupaev date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN Extract(YEAR FROM age(synnikuupaev));
    END;
$$;


--
-- TOC entry 261 (class 1255 OID 25058)
-- Name: sp_uus_turniir(character varying, date, integer, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_uus_turniir(IN t_nimi character varying, IN alguskuupaev date, IN paevade_arv integer, IN a_asula character varying)
    LANGUAGE plpgsql
    AS $$
    DECLARE i_id integer; -- defineerime muutuja, kuhu paneme asula id
    arv integer:=0; -- defineerime muutuja, milleks oleks sellenimeliste asulate arv
loppkuupaev date:= alguskuupaev + (paevade_arv -1);
BEGIN
    SELECT count(*) INTO arv FROM asulad WHERE nimi=a_asula; --loendame kas sellise nimega asulaid on olemas asulate tabelis
    IF arv=0 THEN -- kui pole, siis lisame
        INSERT INTO asulad (nimi) VALUES (a_asula);
    END IF; --kui on, siis ei tehta midagi ehk siis asulat ei lisata

    SELECT asulad.id INTO i_id FROM asulad WHERE asulad.nimi=a_asula; --asulate tabelist väljastame asula id eelnevalt defineeritud muutujasse
    INSERT INTO turniirid (nimi, alguskuupaev, loppkuupaev, asula) VALUES (t_nimi ,alguskuupaev, loppkuupaev, i_id); --sisestame klubi, mille nimi on parameetrina antud ja id saime asulate tabelist

	IF loppkuupaev = alguskuupaev THEN
RAISE NOTICE 'Lisati turniir %, mis toimub % asulas %.', t_nimi, alguskuupaev, a_asula;
else 
RAISE NOTICE 'Lisati turniir %, mis toimub % kuni % asulas  %.', t_nimi, alguskuupaev, loppkuupaev, a_asula;   
END IF;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 24854)
-- Name: asulad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asulad (
    id integer NOT NULL,
    nimi character varying(100) NOT NULL
);


--
-- TOC entry 220 (class 1259 OID 24859)
-- Name: asulad_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asulad_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5178 (class 0 OID 0)
-- Dependencies: 220
-- Name: asulad_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asulad_id_seq OWNED BY public.asulad.id;


--
-- TOC entry 221 (class 1259 OID 24860)
-- Name: inimesed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inimesed (
    eesnimi character varying(70) NOT NULL,
    perenimi character varying(100) NOT NULL,
    sugu character(1) NOT NULL,
    synnipaev date NOT NULL,
    sisestatud timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    isikukood character varying(11),
    CONSTRAINT inimesed_sugu_check CHECK (((sugu = 'm'::bpchar) OR (sugu = 'n'::bpchar)))
);


--
-- TOC entry 222 (class 1259 OID 24870)
-- Name: isikud; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.isikud (
    id integer NOT NULL,
    eesnimi character varying(50) NOT NULL,
    perenimi character varying(50) NOT NULL,
    isikukood character varying(11),
    klubis integer,
    synniaeg date,
    sugu character(1) DEFAULT 'm'::bpchar NOT NULL,
    ranking integer
);


--
-- TOC entry 223 (class 1259 OID 24878)
-- Name: isikud_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.isikud_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5179 (class 0 OID 0)
-- Dependencies: 223
-- Name: isikud_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.isikud_id_seq OWNED BY public.isikud.id;


--
-- TOC entry 224 (class 1259 OID 24879)
-- Name: klubid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.klubid (
    id integer NOT NULL,
    nimi character varying(100) NOT NULL,
    asula integer
);


--
-- TOC entry 225 (class 1259 OID 24884)
-- Name: klubid_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.klubid_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5180 (class 0 OID 0)
-- Dependencies: 225
-- Name: klubid_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.klubid_id_seq OWNED BY public.klubid.id;


--
-- TOC entry 226 (class 1259 OID 24885)
-- Name: partiid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.partiid (
    turniir integer NOT NULL,
    algushetk timestamp without time zone NOT NULL,
    lopphetk timestamp without time zone,
    valge integer NOT NULL,
    must integer NOT NULL,
    valge_tulemus smallint,
    must_tulemus smallint,
    id integer NOT NULL,
    CONSTRAINT ajakontroll CHECK ((lopphetk > algushetk)),
    CONSTRAINT vastavus CHECK (((valge_tulemus + must_tulemus) = 2))
);


--
-- TOC entry 227 (class 1259 OID 24895)
-- Name: v_isikudklubid; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_isikudklubid AS
 SELECT (((isikud.perenimi)::text || ', '::text) || (isikud.eesnimi)::text) AS isik_nimi,
    isikud.id AS isik_id,
    isikud.synniaeg,
    klubid.nimi AS klubi_nimi,
    klubid.id AS klubi_id,
    isikud.ranking
   FROM (public.isikud
     JOIN public.klubid ON ((isikud.klubis = klubid.id)));


--
-- TOC entry 228 (class 1259 OID 24899)
-- Name: v_punktid; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_punktid AS
 SELECT partiid.id AS partii,
    partiid.turniir,
    partiid.valge AS mangija,
    'V'::text AS varv,
    ((partiid.valge_tulemus)::numeric * 0.5) AS punkt
   FROM public.partiid
UNION ALL
 SELECT partiid.id AS partii,
    partiid.turniir,
    partiid.must AS mangija,
    'M'::text AS varv,
    ((partiid.must_tulemus)::numeric * 0.5) AS punkt
   FROM public.partiid;


--
-- TOC entry 229 (class 1259 OID 24903)
-- Name: mv_edetabelid; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.mv_edetabelid AS
 SELECT ik.isik_id AS id,
    ik.isik_nimi AS mangija,
    ik.synniaeg,
    ik.ranking,
    ik.klubi_nimi AS klubi,
    p.turniir,
    sum(p.punkt) AS punkte
   FROM (public.v_isikudklubid ik
     JOIN public.v_punktid p ON ((ik.isik_id = p.mangija)))
  GROUP BY ik.isik_id, ik.isik_nimi, ik.synniaeg, ik.ranking, ik.klubi_nimi, p.turniir
  WITH NO DATA;


--
-- TOC entry 230 (class 1259 OID 24910)
-- Name: mv_partiide_arv_valgetega; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.mv_partiide_arv_valgetega AS
 SELECT isikud.eesnimi,
    isikud.perenimi,
    count(DISTINCT partiid.id) AS partiisid_valgetega
   FROM (public.isikud
     LEFT JOIN public.partiid ON ((isikud.id = partiid.valge)))
  GROUP BY isikud.id, isikud.eesnimi, isikud.perenimi
  WITH NO DATA;


--
-- TOC entry 231 (class 1259 OID 24915)
-- Name: partiid_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.partiid_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5181 (class 0 OID 0)
-- Dependencies: 231
-- Name: partiid_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.partiid_id_seq OWNED BY public.partiid.id;


--
-- TOC entry 232 (class 1259 OID 24916)
-- Name: riigid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.riigid (
    id integer NOT NULL,
    nimi character varying(100) NOT NULL,
    pealinn character varying(100) NOT NULL,
    rahvaarv integer,
    pindala integer,
    skp_mld numeric(8,3)
);


--
-- TOC entry 233 (class 1259 OID 24922)
-- Name: riigid_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.riigid_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5182 (class 0 OID 0)
-- Dependencies: 233
-- Name: riigid_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.riigid_id_seq OWNED BY public.riigid.id;


--
-- TOC entry 234 (class 1259 OID 24923)
-- Name: tooted; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tooted (
    id integer NOT NULL,
    nimi character varying(70)
);


--
-- TOC entry 235 (class 1259 OID 24927)
-- Name: tooted_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tooted_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5183 (class 0 OID 0)
-- Dependencies: 235
-- Name: tooted_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tooted_id_seq OWNED BY public.tooted.id;


--
-- TOC entry 236 (class 1259 OID 24928)
-- Name: turniirid; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.turniirid (
    id integer NOT NULL,
    nimi character varying(100) NOT NULL,
    alguskuupaev date NOT NULL,
    loppkuupaev date,
    asula integer,
    CONSTRAINT ajakontroll CHECK ((alguskuupaev <= loppkuupaev))
);


--
-- TOC entry 237 (class 1259 OID 24935)
-- Name: turniirid_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.turniirid_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5184 (class 0 OID 0)
-- Dependencies: 237
-- Name: turniirid_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.turniirid_id_seq OWNED BY public.turniirid.id;


--
-- TOC entry 238 (class 1259 OID 24936)
-- Name: v_edetabelid; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_edetabelid AS
 SELECT ik.isik_id AS id,
    ik.isik_nimi AS mangija,
    ik.synniaeg,
    ik.ranking,
    ik.klubi_nimi AS klubi,
    p.turniir,
    sum(p.punkt) AS punkte
   FROM (public.v_isikudklubid ik
     JOIN public.v_punktid p ON ((ik.isik_id = p.mangija)))
  GROUP BY ik.isik_id, ik.isik_nimi, ik.synniaeg, ik.ranking, ik.klubi_nimi, p.turniir;


--
-- TOC entry 239 (class 1259 OID 24941)
-- Name: v_keskminepartii; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_keskminepartii AS
 SELECT turniirid.nimi AS turniiri_nimi,
    avg((EXTRACT(epoch FROM (partiid.lopphetk - partiid.algushetk)) / (60)::numeric)) AS keskmine_partii
   FROM (public.turniirid
     JOIN public.partiid ON ((turniirid.id = partiid.turniir)))
  GROUP BY turniirid.id, turniirid.nimi;


--
-- TOC entry 240 (class 1259 OID 24946)
-- Name: v_klubi54; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_klubi54 AS
 SELECT eesnimi,
    perenimi,
    synniaeg,
    ranking,
    klubis AS klubi_id
   FROM public.isikud
  WHERE (klubis = 54)
  WITH CASCADED CHECK OPTION;


--
-- TOC entry 241 (class 1259 OID 24950)
-- Name: v_klubipartiikogused; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_klubipartiikogused AS
 SELECT klubid.nimi AS klubi_nimi,
    count(DISTINCT partiid.id) AS partiisid
   FROM ((public.klubid
     JOIN public.isikud ON ((klubid.id = isikud.klubis)))
     JOIN public.partiid ON (((isikud.id = partiid.valge) OR (isikud.id = partiid.must))))
  GROUP BY klubid.id, klubid.nimi;


--
-- TOC entry 242 (class 1259 OID 24955)
-- Name: v_kolme_klubi_kohtumine_parimad; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_kolme_klubi_kohtumine_parimad AS
 SELECT v_edetabelid.mangija,
    v_edetabelid.punkte AS punktisumma
   FROM (public.v_edetabelid
     JOIN public.turniirid ON ((v_edetabelid.turniir = turniirid.id)))
  WHERE ((turniirid.nimi)::text = 'Kolme klubi kohtumine'::text)
  ORDER BY v_edetabelid.punkte DESC
 LIMIT 3;


--
-- TOC entry 243 (class 1259 OID 24959)
-- Name: v_maletaht; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_maletaht AS
 SELECT i.id,
    i.eesnimi,
    i.perenimi,
    i.isikukood,
    i.klubis,
    i.synniaeg,
    i.sugu,
    i.ranking
   FROM (public.isikud i
     JOIN public.klubid k ON ((i.klubis = k.id)))
  WHERE ((k.nimi)::text = 'Maletäht'::text);


--
-- TOC entry 244 (class 1259 OID 24963)
-- Name: v_partiid; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_partiid AS
 SELECT p.id,
    p.turniir,
    p.algushetk AS algus,
    v.isik_nimi AS valge_nimi,
    v.klubi_nimi AS valge_klubi,
    ((p.valge_tulemus)::numeric / 2.0) AS valge_punkt,
    m.isik_nimi AS must_nimi,
    m.klubi_nimi AS must_klubi,
    ((p.must_tulemus)::numeric / 2.0) AS must_punkt
   FROM public.partiid p,
    public.v_isikudklubid v,
    public.v_isikudklubid m
  WHERE ((p.valge = v.isik_id) AND (p.must = m.isik_id));


--
-- TOC entry 245 (class 1259 OID 24967)
-- Name: v_partiidpisi; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_partiidpisi AS
 SELECT p.id,
    (((v.eesnimi)::text || ' '::text) || (v.perenimi)::text) AS valge_mangija,
    ((p.valge_tulemus)::numeric / 2.0) AS valge_punkt,
    (((m.eesnimi)::text || ' '::text) || (m.perenimi)::text) AS must_mangija,
    ((p.must_tulemus)::numeric / 2.0) AS must_punkt
   FROM ((public.partiid p
     JOIN public.isikud v ON ((p.valge = v.id)))
     JOIN public.isikud m ON ((p.must = m.id)));


--
-- TOC entry 246 (class 1259 OID 24972)
-- Name: v_turniiripartiid; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_turniiripartiid AS
 SELECT turniirid.nimi AS turniir_nimi,
    asulad.nimi AS toimumiskoht,
    partiid.id AS partii_id,
    partiid.algushetk AS partii_algus,
    partiid.lopphetk AS partii_lopp,
        CASE
            WHEN (partiid.valge_tulemus = 2) THEN 'valge'::text
            WHEN (partiid.must_tulemus = 2) THEN 'must'::text
            ELSE 'viik'::text
        END AS kes_voitis
   FROM ((public.turniirid
     JOIN public.partiid ON ((partiid.turniir = turniirid.id)))
     JOIN public.asulad ON ((turniirid.asula = asulad.id)));


--
-- TOC entry 4947 (class 2604 OID 24977)
-- Name: asulad id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asulad ALTER COLUMN id SET DEFAULT nextval('public.asulad_id_seq'::regclass);


--
-- TOC entry 4949 (class 2604 OID 24978)
-- Name: isikud id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isikud ALTER COLUMN id SET DEFAULT nextval('public.isikud_id_seq'::regclass);


--
-- TOC entry 4951 (class 2604 OID 24979)
-- Name: klubid id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.klubid ALTER COLUMN id SET DEFAULT nextval('public.klubid_id_seq'::regclass);


--
-- TOC entry 4952 (class 2604 OID 24980)
-- Name: partiid id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiid ALTER COLUMN id SET DEFAULT nextval('public.partiid_id_seq'::regclass);


--
-- TOC entry 4953 (class 2604 OID 24981)
-- Name: riigid id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.riigid ALTER COLUMN id SET DEFAULT nextval('public.riigid_id_seq'::regclass);


--
-- TOC entry 4954 (class 2604 OID 24982)
-- Name: tooted id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tooted ALTER COLUMN id SET DEFAULT nextval('public.tooted_id_seq'::regclass);


--
-- TOC entry 4955 (class 2604 OID 24983)
-- Name: turniirid id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.turniirid ALTER COLUMN id SET DEFAULT nextval('public.turniirid_id_seq'::regclass);


--
-- TOC entry 5156 (class 0 OID 24854)
-- Dependencies: 219
-- Data for Name: asulad; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.asulad VALUES (1, 'Pärnu');
INSERT INTO public.asulad VALUES (2, 'Valga');
INSERT INTO public.asulad VALUES (3, 'Elva');
INSERT INTO public.asulad VALUES (4, 'Narva');
INSERT INTO public.asulad VALUES (5, 'Tartu');
INSERT INTO public.asulad VALUES (6, 'Viljandi');
INSERT INTO public.asulad VALUES (7, 'Otepää');
INSERT INTO public.asulad VALUES (8, 'Viiratsi');
INSERT INTO public.asulad VALUES (9, 'Kambja');
INSERT INTO public.asulad VALUES (10, 'Tallinn');


--
-- TOC entry 5158 (class 0 OID 24860)
-- Dependencies: 221
-- Data for Name: inimesed; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.inimesed VALUES ('Arne', 'Kerik', 'm', '2005-10-11', '2026-03-15 13:08:59.482532', '50510110330');


--
-- TOC entry 5159 (class 0 OID 24870)
-- Dependencies: 222
-- Data for Name: isikud; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.isikud VALUES (9, 'Tarmo', 'Kooser', '37209112028', NULL, '1972-09-11', 'm', 1076);
INSERT INTO public.isikud VALUES (71, 'Arvo', 'Mets', '33911230101', 51, '1939-11-23', 'm', 1066);
INSERT INTO public.isikud VALUES (73, 'Pjotr', 'Pustota', '36602240707', 59, '1966-02-24', 'm', 1646);
INSERT INTO public.isikud VALUES (74, 'Kalle', 'Kivine', '36006230808', 57, '1960-06-23', 'm', 1411);
INSERT INTO public.isikud VALUES (78, 'Andrei', 'Sosnov', '37704220102', 59, '1977-04-22', 'm', 1813);
INSERT INTO public.isikud VALUES (12, 'Piia', 'Looser', '47303142014', 50, '1973-03-14', 'n', 1091);
INSERT INTO public.isikud VALUES (10, 'Tiina', 'Kooser', '47401010224', NULL, '1974-01-01', 'n', 1027);
INSERT INTO public.isikud VALUES (8, 'Taimi', 'Sabel', '47510142025', NULL, '1975-10-14', 'n', 1851);
INSERT INTO public.isikud VALUES (199, 'Sander', 'Saabas', '38707303030', 61, '1987-07-30', 'm', 1047);
INSERT INTO public.isikud VALUES (201, 'Lembit', 'Allveelaev', '36608080808', 61, '1966-08-08', 'm', 1040);
INSERT INTO public.isikud VALUES (13, 'Laura', 'Kask', '47303142020', NULL, '1973-03-14', 'n', 1268);
INSERT INTO public.isikud VALUES (6, 'Kaia', 'Maja', '47001221010', NULL, '1970-01-22', 'n', 1704);
INSERT INTO public.isikud VALUES (193, 'Heli', 'Jälg', '48112313131', 61, '1981-12-31', 'n', 1429);
INSERT INTO public.isikud VALUES (194, 'Kaja', 'Lood', '47005040405', 61, '1970-05-04', 'n', 1006);
INSERT INTO public.isikud VALUES (195, 'Laine', 'Hari', '46807171720', 61, '1968-07-17', 'n', 1124);
INSERT INTO public.isikud VALUES (196, 'Kalju', 'Saaremets', '36308171015', 61, '1963-08-17', 'm', 1205);
INSERT INTO public.isikud VALUES (2, 'Margus', 'Muru', '37602022016', 61, '1976-02-02', 'm', 1167);
INSERT INTO public.isikud VALUES (90, 'Urmas', 'Ubin', '35803081803', 58, '1958-03-08', 'm', 1028);
INSERT INTO public.isikud VALUES (162, 'Urmas', 'Ümbrik', '37304152020', 52, '1973-04-15', 'm', 1039);
INSERT INTO public.isikud VALUES (198, 'Urmas', 'Uljas', '36805221413', 61, '1968-05-22', 'm', 1005);
INSERT INTO public.isikud VALUES (93, 'Nadja', 'Puhasmaa', '45906301219', 57, '1959-06-30', 'n', 1058);
INSERT INTO public.isikud VALUES (94, 'Maria', 'Lihtne', '44907172613', 54, '1949-07-17', 'n', 1075);
INSERT INTO public.isikud VALUES (148, 'Heli', 'Kopter', '47108271519', 50, '1971-08-27', 'n', 1654);
INSERT INTO public.isikud VALUES (150, 'Katrin', 'Kask', '47011182050', 50, '1970-11-18', 'n', 1298);
INSERT INTO public.isikud VALUES (151, 'Kati', 'Karu', '46110221681', 50, '1961-10-22', 'n', 1030);
INSERT INTO public.isikud VALUES (152, 'Pille', 'Porgand', '46809101030', 50, '1968-09-10', 'n', 1144);
INSERT INTO public.isikud VALUES (157, 'Kristi', 'Kirves', '46901173020', 52, '1969-01-17', 'n', 1050);
INSERT INTO public.isikud VALUES (160, 'Ulvi', 'Uus', '46802012414', 52, '1968-02-01', 'n', 1175);
INSERT INTO public.isikud VALUES (163, 'Tatjana', 'Umnaja', '45510092514', 53, '1955-10-09', 'n', 1045);
INSERT INTO public.isikud VALUES (154, 'Ingo', 'Ilus', '36712044050', 55, '1967-12-04', 'm', 1041);
INSERT INTO public.isikud VALUES (165, 'Aljona', 'Aljas', '46603312628', 53, '1966-03-31', 'n', 1088);
INSERT INTO public.isikud VALUES (171, 'Sanna', 'Sari', '47309291414', 56, '1973-09-29', 'n', 1035);
INSERT INTO public.isikud VALUES (173, 'Hiie', 'Hiid', '47704143256', 56, '1977-04-14', 'n', 1453);
INSERT INTO public.isikud VALUES (175, 'Anna', 'Raha', '46605012233', 56, '1966-05-01', 'n', 1014);
INSERT INTO public.isikud VALUES (186, 'Tiiu', 'Talutütar', '45406124152', 60, '1954-06-12', 'n', 1048);
INSERT INTO public.isikud VALUES (187, 'Ere', 'Valgus', '48108182819', 60, '1981-08-18', 'n', 1002);
INSERT INTO public.isikud VALUES (80, 'Henno', 'Hiis', '37907063645', 55, '1976-07-06', 'm', 1237);
INSERT INTO public.isikud VALUES (86, 'Toomas', 'Remmelgas', '37812082134', 54, '1978-12-08', 'm', 1010);
INSERT INTO public.isikud VALUES (88, 'Mihkel', 'Maakamar', '38702106253', 59, '1987-02-10', 'm', 1020);
INSERT INTO public.isikud VALUES (89, 'Artur', 'Muld', '36911235164', 58, '1969-11-23', 'm', 1063);
INSERT INTO public.isikud VALUES (92, 'Toomas', 'Umnik', '36803261144', 57, '1968-03-26', 'm', 1029);
INSERT INTO public.isikud VALUES (145, 'Tarmo', 'Tarm', '36710301122', 50, '1967-10-30', 'm', 1128);
INSERT INTO public.isikud VALUES (146, 'Peeter', 'Peet', '36502125462', 50, '1965-02-12', 'm', 1053);
INSERT INTO public.isikud VALUES (79, 'Helina', 'Hiis', '46909099999', 55, '1969-09-09', 'n', 1000);
INSERT INTO public.isikud VALUES (82, 'Maria', 'Murakas', '46701226020', 54, '1967-01-22', 'n', 2013);
INSERT INTO public.isikud VALUES (83, 'Maria', 'Medvedovna', '47409193456', 58, '1974-09-19', 'n', 1492);
INSERT INTO public.isikud VALUES (85, 'Liis', 'Metsonen', '48006065123', 54, '1980-06-06', 'n', 1295);
INSERT INTO public.isikud VALUES (87, 'Anna', 'Ristik', '47606143265', 55, '1976-06-14', 'n', 1125);
INSERT INTO public.isikud VALUES (91, 'Jelena', 'Pirn', '46210125040', 58, '1962-10-12', 'n', 1068);
INSERT INTO public.isikud VALUES (72, 'Maari', 'Mustikas', '48012250202', 54, '1980-12-25', 'n', 1005);
INSERT INTO public.isikud VALUES (75, 'Malle', 'Maasikas', '46906220808', 57, '1969-06-22', 'n', 1645);
INSERT INTO public.isikud VALUES (167, 'Valve', 'Vask', '45602091010', 53, '1956-02-09', 'n', 1116);
INSERT INTO public.isikud VALUES (149, 'Kalju', 'Kotkas', '35306032623', 50, '1953-06-03', 'm', 1090);
INSERT INTO public.isikud VALUES (153, 'Ilo', 'Ilus', '37502282135', 55, '1975-02-28', 'm', 1343);
INSERT INTO public.isikud VALUES (155, 'Mart', 'Mari', '37602232513', 55, '1976-02-23', 'm', 1249);
INSERT INTO public.isikud VALUES (161, 'Uljas', 'Ratsanik', '38108203514', 52, '1981-08-20', 'm', 1132);
INSERT INTO public.isikud VALUES (164, 'Boriss', 'Borissov', '36909211561', 53, '1969-09-21', 'm', 1039);
INSERT INTO public.isikud VALUES (166, 'Mihkel', 'Välk', '37009302563', 53, '1970-09-30', 'm', 1012);
INSERT INTO public.isikud VALUES (168, 'Peeter', 'Aljas', '36911112528', 53, '1969-11-11', 'm', 1086);
INSERT INTO public.isikud VALUES (169, 'Meelis', 'Meel', '36709252525', 56, '1967-09-25', 'm', 1622);
INSERT INTO public.isikud VALUES (170, 'Mati', 'All', '36511284135', 56, '1965-11-28', 'm', 1001);
INSERT INTO public.isikud VALUES (172, 'Peeter', 'Sari', '37011161616', 56, '1970-11-16', 'm', 2060);
INSERT INTO public.isikud VALUES (174, 'Ahto', 'Palk', '38311152463', 56, '1983-11-15', 'm', 1138);
INSERT INTO public.isikud VALUES (176, 'Tormi', 'Hoiatus', '38608015361', 56, '1986-08-01', 'm', 1004);
INSERT INTO public.isikud VALUES (188, 'Toomas', 'Toom', '37501055555', 60, '1975-01-05', 'm', 1061);
INSERT INTO public.isikud VALUES (189, 'Kristjan', 'Kuld', '38609165632', 60, '1986-09-16', 'm', 1068);
INSERT INTO public.isikud VALUES (190, 'Kaarel', 'Kaaren', '36911306452', 60, '1969-11-30', 'm', 1057);
INSERT INTO public.isikud VALUES (191, 'Kait', 'Kalamees', '37905312634', 60, '1979-05-31', 'm', 1006);
INSERT INTO public.isikud VALUES (158, 'Anneli', 'Mets', '46511132627', 52, '1965-11-13', 'n', 1628);
INSERT INTO public.isikud VALUES (76, 'Linda', 'Sammal', '46710101010', 58, '1967-10-10', 'n', 1943);
INSERT INTO public.isikud VALUES (84, 'Ilona', 'Polje', '48201291516', 51, '1982-01-29', 'n', 1086);
INSERT INTO public.isikud VALUES (77, 'Arvo', 'Angervaks', '35911111111', 59, '1959-11-11', 'm', 1149);
INSERT INTO public.isikud VALUES (81, 'Irys', 'Kompvek', '46901195849', 51, '1969-01-19', 'n', 1053);
INSERT INTO public.isikud VALUES (147, 'Kalev', 'Jõud', '35304040404', 50, '1953-04-04', 'm', 1255);
INSERT INTO public.isikud VALUES (192, 'Keiu', 'Või', '48412242424', 61, '1984-12-24', 'n', 1047);
INSERT INTO public.isikud VALUES (197, 'Priit', 'Põder', '36709291416', 61, '1967-09-29', 'm', 1666);
INSERT INTO public.isikud VALUES (177, 'Ahti', 'Mõisamees', '37701093658', 56, '1977-01-09', 'm', 1223);
INSERT INTO public.isikud VALUES (156, 'Tõnu', 'Tõrs', '34805050505', 52, '1948-05-05', 'm', 1497);
INSERT INTO public.isikud VALUES (159, 'Tõnis', 'Tõrv', '36609112425', 52, '1966-09-11', 'm', 1289);
INSERT INTO public.isikud VALUES (200, 'Siim', 'Susi', '37101012048', 51, '1971-01-01', 'm', 1217);
INSERT INTO public.isikud VALUES (15, 'Oleg', 'Oll', '37806300001', 4, '1978-06-30', 'm', 1200);
INSERT INTO public.isikud VALUES (17, 'Olga', 'Oll', '48005150002', 4, '1980-05-15', 'n', 1150);
INSERT INTO public.isikud VALUES (18, 'Vahur', 'Kahur', '38510120003', 4, '1985-10-12', 'm', 1540);
INSERT INTO public.isikud VALUES (19, 'Valli', 'Kraav', '49002200004', 4, '1990-02-20', 'n', 1320);
INSERT INTO public.isikud VALUES (20, 'Valter', 'Vale', '37508050005', 4, '1975-08-05', 'm', 1780);
INSERT INTO public.isikud VALUES (21, 'Piibe', 'Leht', NULL, 54, NULL, 'm', NULL);


--
-- TOC entry 5161 (class 0 OID 24879)
-- Dependencies: 224
-- Data for Name: klubid; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.klubid VALUES (59, 'Musta kivi kummardajad', 5);
INSERT INTO public.klubid VALUES (55, 'Ruudu Liine', 5);
INSERT INTO public.klubid VALUES (51, 'Laudnikud', 5);
INSERT INTO public.klubid VALUES (54, 'Ajurebend', 5);
INSERT INTO public.klubid VALUES (50, 'Raudne Ratsu', 10);
INSERT INTO public.klubid VALUES (52, 'Pärnu Parimad', 1);
INSERT INTO public.klubid VALUES (53, 'Vabaettur', 4);
INSERT INTO public.klubid VALUES (56, 'Maletäht', 10);
INSERT INTO public.klubid VALUES (60, 'Chess', 6);
INSERT INTO public.klubid VALUES (61, 'Areng', 10);
INSERT INTO public.klubid VALUES (1, 'Tallinna ratsud', 10);
INSERT INTO public.klubid VALUES (3, 'Odamehed', 5);
INSERT INTO public.klubid VALUES (4, 'Osav oda', 7);
INSERT INTO public.klubid VALUES (58, 'Valge Mask', 2);
INSERT INTO public.klubid VALUES (57, 'Võitmatu Valge', 5);


--
-- TOC entry 5163 (class 0 OID 24885)
-- Dependencies: 226
-- Data for Name: partiid; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.partiid VALUES (43, '2006-06-04 08:01:00', '2006-06-04 08:33:22', 150, 75, 2, 0, 1);
INSERT INTO public.partiid VALUES (43, '2006-06-04 13:01:00', '2006-06-04 13:29:01', 152, 91, 1, 1, 2);
INSERT INTO public.partiid VALUES (42, '2005-03-04 11:01:00', '2005-03-04 11:27:01', 87, 93, 2, 0, 3);
INSERT INTO public.partiid VALUES (43, '2006-06-04 13:01:00', '2006-06-04 13:11:24', 193, 148, 1, 1, 4);
INSERT INTO public.partiid VALUES (42, '2005-03-04 16:01:00', '2005-03-04 16:22:52', 71, 73, 0, 2, 5);
INSERT INTO public.partiid VALUES (41, '2005-01-12 13:09:00', '2005-01-12 13:32:17', 93, 75, 0, 2, 6);
INSERT INTO public.partiid VALUES (44, '2007-09-01 10:02:00', '2007-09-01 10:22:44', 195, 152, 1, 1, 7);
INSERT INTO public.partiid VALUES (44, '2007-09-01 09:02:00', '2007-09-01 09:26:18', 176, 82, 2, 0, 8);
INSERT INTO public.partiid VALUES (44, '2007-09-01 16:01:00', '2007-09-01 16:17:08', 172, 168, 2, 0, 9);
INSERT INTO public.partiid VALUES (44, '2007-09-01 10:01:00', '2007-09-01 10:41:40', 175, 165, 2, 0, 10);
INSERT INTO public.partiid VALUES (47, '2010-10-14 10:01:00', '2010-10-14 10:27:26', 91, 81, 0, 2, 11);
INSERT INTO public.partiid VALUES (47, '2010-10-14 12:01:00', '2010-10-14 12:21:52', 80, 73, 1, 1, 12);
INSERT INTO public.partiid VALUES (42, '2005-03-04 10:02:00', '2005-03-04 10:29:06', 85, 80, 2, 0, 13);
INSERT INTO public.partiid VALUES (41, '2005-01-12 16:02:00', '2005-01-12 16:24:16', 93, 74, 0, 2, 14);
INSERT INTO public.partiid VALUES (44, '2007-09-01 14:01:00', '2007-09-01 14:17:56', 153, 82, 0, 2, 15);
INSERT INTO public.partiid VALUES (43, '2006-06-04 13:01:00', '2006-06-04 13:34:30', 161, 77, 1, 1, 16);
INSERT INTO public.partiid VALUES (42, '2005-03-04 16:03:00', '2005-03-04 16:39:04', 79, 90, 1, 1, 17);
INSERT INTO public.partiid VALUES (43, '2006-06-04 12:01:00', '2006-06-04 12:13:02', 171, 166, 0, 2, 18);
INSERT INTO public.partiid VALUES (43, '2006-06-04 13:01:00', '2006-06-04 13:28:44', 192, 187, 1, 1, 19);
INSERT INTO public.partiid VALUES (43, '2006-06-04 17:02:00', '2006-06-04 17:41:18', 191, 165, 2, 0, 20);
INSERT INTO public.partiid VALUES (43, '2006-06-04 16:02:00', '2006-06-04 16:32:01', 199, 177, 1, 1, 21);
INSERT INTO public.partiid VALUES (47, '2010-10-14 11:02:00', '2010-10-14 11:22:07', 90, 81, 1, 1, 22);
INSERT INTO public.partiid VALUES (44, '2007-09-01 15:01:00', '2007-09-01 15:28:50', 171, 161, 1, 1, 23);
INSERT INTO public.partiid VALUES (41, '2005-01-12 16:02:00', '2005-01-12 16:24:07', 92, 75, 1, 1, 24);
INSERT INTO public.partiid VALUES (42, '2005-03-04 10:01:00', '2005-03-04 10:30:50', 76, 82, 1, 1, 25);
INSERT INTO public.partiid VALUES (43, '2006-06-04 08:01:00', '2006-06-04 08:28:19', 148, 145, 1, 1, 26);
INSERT INTO public.partiid VALUES (42, '2005-03-04 13:01:00', '2005-03-04 13:34:47', 84, 83, 0, 2, 27);
INSERT INTO public.partiid VALUES (42, '2005-03-04 15:01:00', '2005-03-04 15:22:43', 81, 85, 2, 0, 28);
INSERT INTO public.partiid VALUES (43, '2006-06-04 09:02:00', '2006-06-04 09:36:04', 190, 162, 1, 1, 29);
INSERT INTO public.partiid VALUES (43, '2006-06-04 11:01:00', '2006-06-04 11:22:59', 147, 86, 2, 0, 30);
INSERT INTO public.partiid VALUES (43, '2006-06-04 11:01:00', '2006-06-04 11:21:20', 191, 167, 2, 0, 31);
INSERT INTO public.partiid VALUES (42, '2005-03-04 09:02:00', '2005-03-04 09:23:07', 88, 76, 2, 0, 32);
INSERT INTO public.partiid VALUES (43, '2006-06-04 10:02:00', '2006-06-04 10:14:53', 152, 83, 1, 1, 33);
INSERT INTO public.partiid VALUES (47, '2010-10-14 11:03:00', '2010-10-14 11:37:51', 94, 88, 1, 1, 34);
INSERT INTO public.partiid VALUES (42, '2005-03-04 08:02:00', '2005-03-04 08:29:14', 74, 89, 0, 2, 35);
INSERT INTO public.partiid VALUES (43, '2006-06-04 17:03:00', '2006-06-04 17:40:26', 79, 78, 0, 2, 36);
INSERT INTO public.partiid VALUES (47, '2010-10-14 10:05:00', '2010-10-14 10:36:14', 90, 88, 1, 1, 37);
INSERT INTO public.partiid VALUES (44, '2007-09-01 12:01:00', '2007-09-01 12:33:03', 189, 188, 2, 0, 38);
INSERT INTO public.partiid VALUES (42, '2005-03-04 16:02:00', '2005-03-04 16:35:18', 88, 87, 2, 0, 39);
INSERT INTO public.partiid VALUES (42, '2005-03-04 14:01:00', '2005-03-04 14:22:38', 92, 79, 1, 1, 40);
INSERT INTO public.partiid VALUES (42, '2005-03-04 13:01:00', '2005-03-04 13:21:46', 73, 83, 1, 1, 41);
INSERT INTO public.partiid VALUES (42, '2005-03-04 12:01:00', '2005-03-04 12:25:51', 87, 82, 0, 2, 42);
INSERT INTO public.partiid VALUES (42, '2005-03-04 14:01:00', '2005-03-04 14:22:10', 88, 79, 2, 0, 43);
INSERT INTO public.partiid VALUES (42, '2005-03-04 13:02:00', '2005-03-04 13:32:08', 82, 89, 1, 1, 44);
INSERT INTO public.partiid VALUES (44, '2007-09-01 14:01:00', '2007-09-01 14:35:05', 172, 165, 2, 0, 45);
INSERT INTO public.partiid VALUES (47, '2010-10-14 14:01:00', '2010-10-14 14:23:45', 94, 81, 1, 1, 46);
INSERT INTO public.partiid VALUES (42, '2005-03-04 09:01:00', '2005-03-04 09:19:02', 90, 87, 0, 2, 47);
INSERT INTO public.partiid VALUES (44, '2007-09-01 16:01:00', '2007-09-01 16:28:23', 201, 73, 0, 2, 48);
INSERT INTO public.partiid VALUES (44, '2007-09-01 12:01:00', '2007-09-01 12:28:15', 170, 87, 2, 0, 49);
INSERT INTO public.partiid VALUES (42, '2005-03-04 09:03:00', '2005-03-04 09:33:11', 82, 92, 1, 1, 50);
INSERT INTO public.partiid VALUES (44, '2007-09-01 15:01:00', '2007-09-01 15:18:58', 198, 82, 0, 2, 51);
INSERT INTO public.partiid VALUES (43, '2006-06-04 14:01:00', '2006-06-04 14:33:26', 192, 161, 0, 2, 52);
INSERT INTO public.partiid VALUES (41, '2005-01-12 16:02:00', '2005-01-12 16:14:40', 77, 73, 0, 2, 53);
INSERT INTO public.partiid VALUES (42, '2005-03-04 12:03:00', '2005-03-04 12:19:28', 89, 75, 1, 1, 54);
INSERT INTO public.partiid VALUES (47, '2010-10-14 08:04:00', '2010-10-14 08:28:49', 89, 82, 2, 0, 55);
INSERT INTO public.partiid VALUES (43, '2006-06-04 16:02:00', '2006-06-04 16:26:21', 197, 159, 2, 0, 56);
INSERT INTO public.partiid VALUES (42, '2005-03-04 10:03:00', '2005-03-04 10:31:36', 81, 77, 0, 2, 57);
INSERT INTO public.partiid VALUES (41, '2005-01-12 11:08:00', '2005-01-12 11:35:48', 78, 92, 2, 0, 58);
INSERT INTO public.partiid VALUES (42, '2005-03-04 13:04:00', '2005-03-04 13:14:50', 87, 81, 0, 2, 59);
INSERT INTO public.partiid VALUES (43, '2006-06-04 09:01:00', '2006-06-04 09:22:46', 151, 87, 0, 2, 60);
INSERT INTO public.partiid VALUES (42, '2005-03-04 12:04:00', '2005-03-04 12:17:17', 91, 80, 2, 0, 61);
INSERT INTO public.partiid VALUES (44, '2007-09-01 11:01:00', '2007-09-01 11:19:22', 171, 83, 0, 2, 62);
INSERT INTO public.partiid VALUES (47, '2010-10-14 09:10:00', '2010-10-14 09:45:48', 94, 84, 1, 1, 63);
INSERT INTO public.partiid VALUES (43, '2006-06-04 16:01:00', '2006-06-04 16:39:54', 201, 147, 0, 2, 64);
INSERT INTO public.partiid VALUES (41, '2005-01-12 10:04:00', '2005-01-12 10:28:23', 80, 79, 1, 1, 65);
INSERT INTO public.partiid VALUES (43, '2006-06-04 17:01:00', '2006-06-04 17:25:42', 156, 86, 2, 0, 66);
INSERT INTO public.partiid VALUES (44, '2007-09-01 13:01:00', '2007-09-01 13:31:37', 81, 74, 0, 2, 67);
INSERT INTO public.partiid VALUES (42, '2005-03-04 12:04:00', '2005-03-04 12:15:11', 93, 91, 0, 2, 68);
INSERT INTO public.partiid VALUES (47, '2010-10-14 17:01:00', '2010-10-14 17:16:56', 83, 82, 2, 0, 69);
INSERT INTO public.partiid VALUES (44, '2007-09-01 11:02:00', '2007-09-01 11:28:41', 160, 157, 2, 0, 70);
INSERT INTO public.partiid VALUES (41, '2005-01-12 14:06:00', '2005-01-12 14:24:26', 73, 74, 2, 0, 71);
INSERT INTO public.partiid VALUES (43, '2006-06-04 17:02:00', '2006-06-04 17:18:34', 175, 152, 1, 1, 72);
INSERT INTO public.partiid VALUES (44, '2007-09-01 11:01:00', '2007-09-01 11:15:54', 187, 84, 1, 1, 73);
INSERT INTO public.partiid VALUES (47, '2010-10-14 14:01:00', '2010-10-14 14:22:13', 87, 84, 1, 1, 74);
INSERT INTO public.partiid VALUES (42, '2005-03-04 11:03:00', '2005-03-04 11:24:35', 92, 76, 1, 1, 75);
INSERT INTO public.partiid VALUES (41, '2005-01-12 11:03:00', '2005-01-12 11:31:54', 75, 80, 2, 0, 76);
INSERT INTO public.partiid VALUES (41, '2005-01-12 10:04:00', '2005-01-12 10:33:03', 92, 79, 2, 0, 77);
INSERT INTO public.partiid VALUES (43, '2006-06-04 15:01:00', '2006-06-04 15:19:57', 168, 85, 2, 0, 78);
INSERT INTO public.partiid VALUES (44, '2007-09-01 16:02:00', '2007-09-01 16:37:18', 188, 146, 0, 2, 79);
INSERT INTO public.partiid VALUES (42, '2005-03-04 09:01:00', '2005-03-04 09:19:08', 91, 71, 2, 0, 80);
INSERT INTO public.partiid VALUES (43, '2006-06-04 12:03:00', '2006-06-04 12:30:47', 173, 77, 1, 1, 81);
INSERT INTO public.partiid VALUES (42, '2005-03-04 15:02:00', '2005-03-04 15:26:39', 73, 76, 1, 1, 82);
INSERT INTO public.partiid VALUES (43, '2006-06-04 14:01:00', '2006-06-04 14:20:49', 191, 85, 1, 1, 83);
INSERT INTO public.partiid VALUES (43, '2006-06-04 09:01:00', '2006-06-04 09:19:52', 157, 85, 0, 2, 84);
INSERT INTO public.partiid VALUES (42, '2005-03-04 12:01:00', '2005-03-04 12:23:53', 90, 78, 0, 2, 85);
INSERT INTO public.partiid VALUES (43, '2006-06-04 12:01:00', '2006-06-04 12:31:28', 156, 72, 2, 0, 86);
INSERT INTO public.partiid VALUES (43, '2006-06-04 11:02:00', '2006-06-04 11:25:11', 199, 195, 2, 0, 87);
INSERT INTO public.partiid VALUES (43, '2006-06-04 10:01:00', '2006-06-04 10:24:47', 190, 145, 1, 1, 88);
INSERT INTO public.partiid VALUES (44, '2007-09-01 08:04:00', '2007-09-01 08:22:49', 147, 83, 0, 2, 89);
INSERT INTO public.partiid VALUES (44, '2007-09-01 13:02:00', '2007-09-01 13:36:46', 198, 188, 2, 0, 90);
INSERT INTO public.partiid VALUES (43, '2006-06-04 15:01:00', '2006-06-04 15:16:17', 167, 166, 2, 0, 91);
INSERT INTO public.partiid VALUES (44, '2007-09-01 12:01:00', '2007-09-01 12:20:30', 201, 198, 2, 0, 92);
INSERT INTO public.partiid VALUES (44, '2007-09-01 16:01:00', '2007-09-01 16:31:21', 149, 93, 2, 0, 93);
INSERT INTO public.partiid VALUES (41, '2005-01-12 17:03:00', '2005-01-12 17:26:14', 93, 80, 1, 1, 94);
INSERT INTO public.partiid VALUES (42, '2005-03-04 09:01:00', '2005-03-04 09:15:26', 89, 73, 1, 1, 95);
INSERT INTO public.partiid VALUES (42, '2005-03-04 10:02:00', '2005-03-04 10:26:31', 75, 84, 2, 0, 96);
INSERT INTO public.partiid VALUES (41, '2005-01-12 10:05:00', '2005-01-12 10:29:15', 93, 87, 1, 1, 97);
INSERT INTO public.partiid VALUES (43, '2006-06-04 12:01:00', '2006-06-04 12:31:07', 188, 78, 1, 1, 98);
INSERT INTO public.partiid VALUES (44, '2007-09-01 11:01:00', '2007-09-01 11:30:59', 167, 156, 0, 2, 99);
INSERT INTO public.partiid VALUES (44, '2007-09-01 11:01:00', '2007-09-01 11:28:37', 175, 162, 2, 0, 100);
INSERT INTO public.partiid VALUES (43, '2006-06-04 16:02:00', '2006-06-04 16:21:20', 192, 155, 0, 2, 101);
INSERT INTO public.partiid VALUES (42, '2005-03-04 12:01:00', '2005-03-04 12:19:44', 73, 81, 1, 1, 102);
INSERT INTO public.partiid VALUES (47, '2010-10-14 16:04:00', '2010-10-14 16:23:00', 90, 72, 0, 2, 103);
INSERT INTO public.partiid VALUES (43, '2006-06-04 12:01:00', '2006-06-04 12:25:08', 172, 160, 1, 1, 104);
INSERT INTO public.partiid VALUES (41, '2005-01-12 12:02:00', '2005-01-12 12:25:05', 92, 87, 2, 0, 105);
INSERT INTO public.partiid VALUES (42, '2005-03-04 11:02:00', '2005-03-04 11:26:46', 90, 71, 0, 2, 106);
INSERT INTO public.partiid VALUES (44, '2007-09-01 17:01:00', '2007-09-01 17:31:29', 146, 75, 2, 0, 107);
INSERT INTO public.partiid VALUES (44, '2007-09-01 08:01:00', '2007-09-01 08:18:13', 191, 167, 0, 2, 108);
INSERT INTO public.partiid VALUES (42, '2005-03-04 17:01:00', '2005-03-04 17:21:52', 82, 72, 2, 0, 109);
INSERT INTO public.partiid VALUES (44, '2007-09-01 10:01:00', '2007-09-01 10:33:30', 172, 79, 1, 1, 110);
INSERT INTO public.partiid VALUES (41, '2005-01-12 08:02:00', '2005-01-12 08:19:28', 73, 92, 1, 1, 111);
INSERT INTO public.partiid VALUES (44, '2007-09-01 13:01:00', '2007-09-01 13:30:35', 200, 146, 0, 2, 112);
INSERT INTO public.partiid VALUES (43, '2006-06-04 08:03:00', '2006-06-04 08:35:03', 168, 91, 2, 0, 113);
INSERT INTO public.partiid VALUES (43, '2006-06-04 10:02:00', '2006-06-04 10:17:30', 175, 148, 1, 1, 114);
INSERT INTO public.partiid VALUES (41, '2005-01-12 17:03:00', '2005-01-12 17:22:58', 88, 93, 1, 1, 115);
INSERT INTO public.partiid VALUES (44, '2007-09-01 12:03:00', '2007-09-01 12:31:06', 167, 163, 0, 2, 116);
INSERT INTO public.partiid VALUES (42, '2005-03-04 15:01:00', '2005-03-04 15:25:22', 83, 80, 1, 1, 117);
INSERT INTO public.partiid VALUES (42, '2005-03-04 16:01:00', '2005-03-04 16:30:37', 89, 84, 1, 1, 118);
INSERT INTO public.partiid VALUES (41, '2005-01-12 13:07:00', '2005-01-12 13:32:46', 78, 74, 0, 2, 119);
INSERT INTO public.partiid VALUES (44, '2007-09-01 11:01:00', '2007-09-01 11:23:23', 165, 92, 0, 2, 120);
INSERT INTO public.partiid VALUES (47, '2010-10-14 13:01:00', '2010-10-14 13:27:29', 91, 84, 0, 2, 121);
INSERT INTO public.partiid VALUES (43, '2006-06-04 10:01:00', '2006-06-04 10:20:52', 193, 176, 1, 1, 122);
INSERT INTO public.partiid VALUES (42, '2005-03-04 16:03:00', '2005-03-04 16:31:01', 93, 81, 0, 2, 123);
INSERT INTO public.partiid VALUES (44, '2007-09-01 17:01:00', '2007-09-01 17:22:34', 86, 74, 2, 0, 124);
INSERT INTO public.partiid VALUES (41, '2005-01-12 09:03:00', '2005-01-12 09:30:53', 75, 79, 2, 0, 125);
INSERT INTO public.partiid VALUES (47, '2010-10-14 15:04:00', '2010-10-14 15:26:44', 89, 77, 2, 0, 126);
INSERT INTO public.partiid VALUES (47, '2010-10-14 12:10:00', '2010-10-14 12:30:06', 87, 77, 1, 1, 127);
INSERT INTO public.partiid VALUES (42, '2005-03-04 14:01:00', '2005-03-04 14:29:17', 72, 76, 2, 0, 128);
INSERT INTO public.partiid VALUES (44, '2007-09-01 09:01:00', '2007-09-01 09:21:14', 166, 72, 1, 1, 129);
INSERT INTO public.partiid VALUES (44, '2007-09-01 10:01:00', '2007-09-01 10:30:44', 87, 72, 0, 2, 130);
INSERT INTO public.partiid VALUES (42, '2005-03-04 14:03:00', '2005-03-04 14:25:29', 75, 82, 2, 0, 131);
INSERT INTO public.partiid VALUES (42, '2005-03-04 11:02:00', '2005-03-04 11:30:30', 81, 71, 0, 2, 132);
INSERT INTO public.partiid VALUES (47, '2010-10-14 13:01:00', '2010-10-14 13:21:17', 73, 72, 1, 1, 133);
INSERT INTO public.partiid VALUES (42, '2005-03-04 17:01:00', '2005-03-04 17:25:59', 76, 91, 1, 1, 134);
INSERT INTO public.partiid VALUES (44, '2007-09-01 10:01:00', '2007-09-01 10:25:44', 200, 155, 0, 2, 135);
INSERT INTO public.partiid VALUES (42, '2005-03-04 16:02:00', '2005-03-04 16:33:14', 91, 77, 2, 0, 136);
INSERT INTO public.partiid VALUES (44, '2007-09-01 16:01:00', '2007-09-01 16:25:27', 164, 158, 0, 2, 137);
INSERT INTO public.partiid VALUES (42, '2005-03-04 11:01:00', '2005-03-04 11:25:14', 85, 89, 1, 1, 138);
INSERT INTO public.partiid VALUES (43, '2006-06-04 08:01:00', '2006-06-04 08:29:10', 196, 160, 1, 1, 139);
INSERT INTO public.partiid VALUES (44, '2007-09-01 08:02:00', '2007-09-01 08:28:03', 195, 172, 1, 1, 140);
INSERT INTO public.partiid VALUES (43, '2006-06-04 09:01:00', '2006-06-04 09:35:36', 172, 78, 0, 2, 141);
INSERT INTO public.partiid VALUES (44, '2007-09-01 17:01:00', '2007-09-01 17:27:31', 167, 77, 2, 0, 142);
INSERT INTO public.partiid VALUES (44, '2007-09-01 16:02:00', '2007-09-01 16:25:41', 186, 82, 0, 2, 143);
INSERT INTO public.partiid VALUES (43, '2006-06-04 09:01:00', '2006-06-04 09:23:35', 191, 71, 1, 1, 144);
INSERT INTO public.partiid VALUES (44, '2007-09-01 11:01:00', '2007-09-01 11:20:20', 159, 148, 1, 1, 145);
INSERT INTO public.partiid VALUES (43, '2006-06-04 12:02:00', '2006-06-04 12:21:05', 153, 84, 2, 0, 146);
INSERT INTO public.partiid VALUES (44, '2007-09-01 13:01:00', '2007-09-01 13:23:54', 197, 90, 2, 0, 147);
INSERT INTO public.partiid VALUES (43, '2006-06-04 11:01:00', '2006-06-04 11:21:29', 172, 71, 0, 2, 148);
INSERT INTO public.partiid VALUES (42, '2005-03-04 11:02:00', '2005-03-04 11:22:12', 88, 81, 2, 0, 149);
INSERT INTO public.partiid VALUES (43, '2006-06-04 12:02:00', '2006-06-04 12:31:59', 157, 92, 0, 2, 150);
INSERT INTO public.partiid VALUES (44, '2007-09-01 15:01:00', '2007-09-01 15:18:10', 194, 80, 2, 0, 151);
INSERT INTO public.partiid VALUES (43, '2006-06-04 17:02:00', '2006-06-04 17:24:39', 157, 72, 0, 2, 152);
INSERT INTO public.partiid VALUES (42, '2005-03-04 12:03:00', '2005-03-04 12:26:21', 83, 79, 1, 1, 153);
INSERT INTO public.partiid VALUES (43, '2006-06-04 15:01:00', '2006-06-04 15:32:38', 197, 176, 2, 0, 154);
INSERT INTO public.partiid VALUES (44, '2007-09-01 16:01:00', '2007-09-01 16:26:22', 190, 77, 1, 1, 155);
INSERT INTO public.partiid VALUES (44, '2007-09-01 17:01:00', '2007-09-01 17:24:23', 173, 171, 0, 2, 156);
INSERT INTO public.partiid VALUES (42, '2005-03-04 16:02:00', '2005-03-04 16:35:18', 80, 82, 0, 2, 157);
INSERT INTO public.partiid VALUES (44, '2007-09-01 09:01:00', '2007-09-01 09:19:09', 175, 84, 1, 1, 158);
INSERT INTO public.partiid VALUES (43, '2006-06-04 11:01:00', '2006-06-04 11:32:10', 165, 72, 2, 0, 159);
INSERT INTO public.partiid VALUES (42, '2005-03-04 09:01:00', '2005-03-04 09:33:28', 78, 75, 0, 2, 160);
INSERT INTO public.partiid VALUES (42, '2005-03-04 14:01:00', '2005-03-04 14:36:27', 86, 79, 1, 1, 161);
INSERT INTO public.partiid VALUES (44, '2007-09-01 09:01:00', '2007-09-01 09:22:25', 159, 153, 1, 1, 162);
INSERT INTO public.partiid VALUES (42, '2005-03-04 17:05:00', '2005-03-04 17:27:42', 92, 83, 1, 1, 163);
INSERT INTO public.partiid VALUES (43, '2006-06-04 12:01:00', '2006-06-04 12:14:51', 152, 81, 1, 1, 164);
INSERT INTO public.partiid VALUES (42, '2005-03-04 10:01:00', '2005-03-04 10:14:20', 91, 83, 2, 0, 165);
INSERT INTO public.partiid VALUES (44, '2007-09-01 12:02:00', '2007-09-01 12:20:01', 200, 173, 0, 2, 166);
INSERT INTO public.partiid VALUES (41, '2005-01-12 08:04:00', '2005-01-12 08:35:35', 77, 87, 2, 0, 167);
INSERT INTO public.partiid VALUES (43, '2006-06-04 16:02:00', '2006-06-04 16:16:48', 186, 81, 2, 0, 168);
INSERT INTO public.partiid VALUES (43, '2006-06-04 16:01:00', '2006-06-04 16:26:22', 200, 76, 1, 1, 169);
INSERT INTO public.partiid VALUES (47, '2010-10-14 09:04:00', '2010-10-14 09:23:35', 85, 83, 0, 2, 170);
INSERT INTO public.partiid VALUES (43, '2006-06-04 10:01:00', '2006-06-04 10:32:00', 171, 164, 0, 2, 171);
INSERT INTO public.partiid VALUES (43, '2006-06-04 17:01:00', '2006-06-04 17:37:03', 173, 94, 1, 1, 172);
INSERT INTO public.partiid VALUES (44, '2007-09-01 11:01:00', '2007-09-01 11:25:33', 150, 93, 0, 2, 173);
INSERT INTO public.partiid VALUES (43, '2006-06-04 16:01:00', '2006-06-04 16:29:59', 93, 72, 2, 0, 174);
INSERT INTO public.partiid VALUES (41, '2005-01-12 12:04:00', '2005-01-12 12:22:23', 73, 79, 0, 2, 175);
INSERT INTO public.partiid VALUES (43, '2006-06-04 12:01:00', '2006-06-04 12:25:45', 190, 93, 0, 2, 176);
INSERT INTO public.partiid VALUES (43, '2006-06-04 08:02:00', '2006-06-04 08:39:56', 198, 191, 1, 1, 177);
INSERT INTO public.partiid VALUES (47, '2010-10-14 08:03:00', '2010-10-14 08:22:14', 87, 85, 1, 1, 178);
INSERT INTO public.partiid VALUES (41, '2005-01-12 16:05:00', '2005-01-12 16:31:44', 78, 80, 1, 1, 179);
INSERT INTO public.partiid VALUES (47, '2010-10-14 16:02:00', '2010-10-14 16:26:46', 89, 79, 2, 0, 180);
INSERT INTO public.partiid VALUES (43, '2006-06-04 13:03:00', '2006-06-04 13:29:28', 89, 86, 1, 1, 181);
INSERT INTO public.partiid VALUES (42, '2005-03-04 10:01:00', '2005-03-04 10:17:15', 72, 74, 2, 0, 182);
INSERT INTO public.partiid VALUES (43, '2006-06-04 10:01:00', '2006-06-04 10:21:23', 74, 72, 1, 1, 183);
INSERT INTO public.partiid VALUES (43, '2006-06-04 13:01:00', '2006-06-04 13:29:58', 200, 162, 2, 0, 184);
INSERT INTO public.partiid VALUES (42, '2005-03-04 08:01:00', '2005-03-04 08:14:49', 87, 79, 0, 2, 185);
INSERT INTO public.partiid VALUES (41, '2005-01-12 13:04:00', '2005-01-12 13:29:53', 88, 80, 0, 2, 186);
INSERT INTO public.partiid VALUES (44, '2007-09-01 17:01:00', '2007-09-01 17:15:22', 166, 80, 1, 1, 187);
INSERT INTO public.partiid VALUES (44, '2007-09-01 12:01:00', '2007-09-01 12:28:28', 80, 76, 2, 0, 188);
INSERT INTO public.partiid VALUES (43, '2006-06-04 12:01:00', '2006-06-04 12:31:41', 161, 88, 1, 1, 189);
INSERT INTO public.partiid VALUES (41, '2005-01-12 12:09:00', '2005-01-12 12:41:36', 77, 74, 1, 1, 190);
INSERT INTO public.partiid VALUES (42, '2005-03-04 15:01:00', '2005-03-04 15:19:05', 90, 91, 2, 0, 191);
INSERT INTO public.partiid VALUES (44, '2007-09-01 16:01:00', '2007-09-01 16:27:29', 91, 72, 1, 1, 192);
INSERT INTO public.partiid VALUES (44, '2007-09-01 15:01:00', '2007-09-01 15:39:55', 169, 79, 1, 1, 193);
INSERT INTO public.partiid VALUES (47, '2010-10-14 13:05:00', '2010-10-14 13:33:30', 88, 82, 0, 2, 194);
INSERT INTO public.partiid VALUES (41, '2005-01-12 09:01:00', '2005-01-12 09:26:50', 78, 77, 2, 0, 195);
INSERT INTO public.partiid VALUES (42, '2005-03-04 14:03:00', '2005-03-04 14:17:21', 91, 84, 2, 0, 196);
INSERT INTO public.partiid VALUES (43, '2006-06-04 14:01:00', '2006-06-04 14:26:53', 186, 87, 2, 0, 197);
INSERT INTO public.partiid VALUES (47, '2010-10-14 09:01:00', '2010-10-14 09:21:04', 90, 78, 1, 1, 198);
INSERT INTO public.partiid VALUES (42, '2005-03-04 13:02:00', '2005-03-04 13:11:41', 89, 88, 1, 1, 199);
INSERT INTO public.partiid VALUES (44, '2007-09-01 12:01:00', '2007-09-01 12:25:37', 155, 150, 0, 2, 200);
INSERT INTO public.partiid VALUES (44, '2007-09-01 12:02:00', '2007-09-01 12:31:31', 169, 165, 2, 0, 201);
INSERT INTO public.partiid VALUES (43, '2006-06-04 13:02:00', '2006-06-04 13:30:53', 172, 145, 1, 1, 202);
INSERT INTO public.partiid VALUES (44, '2007-09-01 10:01:00', '2007-09-01 10:31:05', 94, 74, 1, 1, 203);
INSERT INTO public.partiid VALUES (43, '2006-06-04 14:02:00', '2006-06-04 14:38:17', 94, 78, 0, 2, 204);
INSERT INTO public.partiid VALUES (42, '2005-03-04 17:01:00', '2005-03-04 17:27:37', 81, 78, 0, 2, 205);
INSERT INTO public.partiid VALUES (42, '2005-03-04 12:01:00', '2005-03-04 12:16:11', 71, 92, 0, 2, 206);
INSERT INTO public.partiid VALUES (42, '2005-03-04 17:02:00', '2005-03-04 17:33:51', 84, 88, 2, 0, 207);
INSERT INTO public.partiid VALUES (44, '2007-09-01 12:01:00', '2007-09-01 12:41:24', 190, 79, 1, 1, 208);
INSERT INTO public.partiid VALUES (44, '2007-09-01 12:01:00', '2007-09-01 12:17:57', 186, 148, 1, 1, 209);
INSERT INTO public.partiid VALUES (43, '2006-06-04 13:01:00', '2006-06-04 13:34:46', 186, 79, 2, 0, 210);
INSERT INTO public.partiid VALUES (42, '2005-03-04 15:01:00', '2005-03-04 15:27:03', 77, 72, 1, 1, 211);
INSERT INTO public.partiid VALUES (42, '2005-03-04 13:01:00', '2005-03-04 13:25:01', 76, 93, 1, 1, 212);
INSERT INTO public.partiid VALUES (43, '2006-06-04 08:01:00', '2006-06-04 08:30:11', 174, 90, 2, 0, 213);
INSERT INTO public.partiid VALUES (43, '2006-06-04 13:02:00', '2006-06-04 13:18:42', 169, 168, 1, 1, 214);
INSERT INTO public.partiid VALUES (42, '2005-03-04 08:01:00', '2005-03-04 08:17:12', 71, 93, 0, 2, 215);
INSERT INTO public.partiid VALUES (44, '2007-09-01 09:03:00', '2007-09-01 09:32:16', 195, 74, 0, 2, 216);
INSERT INTO public.partiid VALUES (43, '2006-06-04 12:02:00', '2006-06-04 12:26:05', 194, 186, 0, 2, 217);
INSERT INTO public.partiid VALUES (47, '2010-10-14 17:01:00', '2010-10-14 17:25:52', 89, 85, 2, 0, 218);
INSERT INTO public.partiid VALUES (42, '2005-03-04 08:05:00', '2005-03-04 08:34:11', 85, 86, 1, 1, 219);
INSERT INTO public.partiid VALUES (42, '2005-03-04 13:01:00', '2005-03-04 13:30:16', 83, 74, 1, 1, 220);
INSERT INTO public.partiid VALUES (42, '2005-03-04 17:01:00', '2005-03-04 17:31:09', 93, 89, 0, 2, 221);
INSERT INTO public.partiid VALUES (43, '2006-06-04 09:01:00', '2006-06-04 09:28:56', 82, 74, 0, 2, 222);
INSERT INTO public.partiid VALUES (44, '2007-09-01 15:02:00', '2007-09-01 15:25:08', 160, 74, 1, 1, 223);
INSERT INTO public.partiid VALUES (44, '2007-09-01 14:01:00', '2007-09-01 14:29:53', 156, 155, 1, 1, 224);
INSERT INTO public.partiid VALUES (47, '2010-10-14 09:04:00', '2010-10-14 09:33:34', 88, 86, 0, 2, 225);
INSERT INTO public.partiid VALUES (44, '2007-09-01 09:01:00', '2007-09-01 09:20:47', 161, 152, 0, 2, 226);
INSERT INTO public.partiid VALUES (47, '2010-10-14 11:04:00', '2010-10-14 11:17:54', 83, 80, 2, 0, 227);
INSERT INTO public.partiid VALUES (42, '2005-03-04 11:01:00', '2005-03-04 11:34:58', 82, 78, 2, 0, 228);
INSERT INTO public.partiid VALUES (43, '2006-06-04 14:01:00', '2006-06-04 14:28:13', 160, 72, 0, 2, 229);
INSERT INTO public.partiid VALUES (47, '2010-10-14 08:01:00', '2010-10-14 08:33:12', 90, 86, 1, 1, 230);
INSERT INTO public.partiid VALUES (43, '2006-06-04 17:01:00', '2006-06-04 17:21:44', 162, 80, 2, 0, 231);
INSERT INTO public.partiid VALUES (42, '2005-03-04 08:05:00', '2005-03-04 08:28:16', 85, 91, 1, 1, 232);
INSERT INTO public.partiid VALUES (47, '2010-10-14 09:06:00', '2010-10-14 09:16:42', 89, 73, 1, 1, 233);
INSERT INTO public.partiid VALUES (42, '2005-03-04 08:01:00', '2005-03-04 08:20:45', 73, 82, 1, 1, 234);
INSERT INTO public.partiid VALUES (42, '2005-03-04 15:02:00', '2005-03-04 15:25:22', 86, 74, 1, 1, 235);
INSERT INTO public.partiid VALUES (43, '2006-06-04 11:01:00', '2006-06-04 11:16:37', 85, 81, 0, 2, 236);
INSERT INTO public.partiid VALUES (43, '2006-06-04 16:03:00', '2006-06-04 16:23:12', 175, 80, 0, 2, 237);
INSERT INTO public.partiid VALUES (47, '2010-10-14 13:01:00', '2010-10-14 13:19:02', 90, 76, 1, 1, 238);
INSERT INTO public.partiid VALUES (41, '2005-01-12 09:03:00', '2005-01-12 09:21:57', 88, 92, 1, 1, 239);
INSERT INTO public.partiid VALUES (47, '2010-10-14 15:03:00', '2010-10-14 15:29:37', 79, 78, 0, 2, 240);
INSERT INTO public.partiid VALUES (47, '2010-10-14 10:02:00', '2010-10-14 10:39:29', 85, 77, 0, 2, 241);
INSERT INTO public.partiid VALUES (42, '2005-03-04 08:02:00', '2005-03-04 08:25:43', 92, 84, 1, 1, 242);
INSERT INTO public.partiid VALUES (44, '2007-09-01 10:01:00', '2007-09-01 10:21:28', 190, 83, 1, 1, 243);
INSERT INTO public.partiid VALUES (42, '2005-03-04 13:01:00', '2005-03-04 13:28:17', 74, 92, 0, 2, 244);
INSERT INTO public.partiid VALUES (47, '2010-10-14 16:01:00', '2010-10-14 16:28:27', 91, 82, 0, 2, 245);
INSERT INTO public.partiid VALUES (47, '2010-10-14 15:07:00', '2010-10-14 15:30:53', 86, 83, 2, 0, 246);
INSERT INTO public.partiid VALUES (42, '2005-03-04 14:04:00', '2005-03-04 14:18:37', 78, 85, 2, 0, 247);
INSERT INTO public.partiid VALUES (44, '2007-09-01 16:04:00', '2007-09-01 16:30:28', 167, 74, 2, 0, 248);
INSERT INTO public.partiid VALUES (41, '2005-01-12 17:02:00', '2005-01-12 17:14:43', 78, 79, 1, 1, 249);
INSERT INTO public.partiid VALUES (44, '2007-09-01 14:01:00', '2007-09-01 14:19:56', 169, 80, 1, 1, 250);
INSERT INTO public.partiid VALUES (42, '2005-03-04 17:03:00', '2005-03-04 17:19:04', 74, 79, 0, 2, 251);
INSERT INTO public.partiid VALUES (44, '2007-09-01 17:01:00', '2007-09-01 17:25:54', 169, 78, 1, 1, 252);
INSERT INTO public.partiid VALUES (43, '2006-06-04 09:01:00', '2006-06-04 09:28:16', 160, 75, 0, 2, 253);
INSERT INTO public.partiid VALUES (44, '2007-09-01 17:02:00', '2007-09-01 17:35:01', 192, 94, 0, 2, 254);
INSERT INTO public.partiid VALUES (44, '2007-09-01 12:01:00', '2007-09-01 12:32:52', 193, 73, 1, 1, 255);
INSERT INTO public.partiid VALUES (42, '2005-03-04 09:01:00', '2005-03-04 09:33:44', 87, 74, 0, 2, 256);
INSERT INTO public.partiid VALUES (47, '2010-10-14 12:02:00', '2010-10-14 12:25:51', 89, 84, 2, 0, 257);
INSERT INTO public.partiid VALUES (43, '2006-06-04 10:03:00', '2006-06-04 10:37:49', 165, 161, 0, 2, 258);
INSERT INTO public.partiid VALUES (42, '2005-03-04 14:02:00', '2005-03-04 14:30:33', 89, 80, 1, 1, 259);
INSERT INTO public.partiid VALUES (43, '2006-06-04 17:02:00', '2006-06-04 17:25:11', 197, 149, 2, 0, 260);
INSERT INTO public.partiid VALUES (42, '2005-03-04 12:01:00', '2005-03-04 12:24:37', 92, 78, 1, 1, 261);
INSERT INTO public.partiid VALUES (43, '2006-06-04 09:01:00', '2006-06-04 09:23:47', 165, 159, 0, 2, 262);
INSERT INTO public.partiid VALUES (44, '2007-09-01 14:01:00', '2007-09-01 14:23:08', 84, 71, 0, 2, 263);
INSERT INTO public.partiid VALUES (43, '2006-06-04 09:01:00', '2006-06-04 09:28:54', 188, 175, 2, 0, 264);
INSERT INTO public.partiid VALUES (44, '2007-09-01 12:01:00', '2007-09-01 12:27:05', 162, 159, 1, 1, 265);
INSERT INTO public.partiid VALUES (44, '2007-09-01 09:01:00', '2007-09-01 09:32:31', 191, 75, 2, 0, 266);
INSERT INTO public.partiid VALUES (47, '2010-10-14 17:01:00', '2010-10-14 17:40:04', 87, 73, 0, 2, 267);
INSERT INTO public.partiid VALUES (42, '2005-03-04 17:02:00', '2005-03-04 17:37:07', 71, 88, 0, 2, 268);
INSERT INTO public.partiid VALUES (42, '2005-03-04 16:02:00', '2005-03-04 16:12:26', 72, 85, 2, 0, 269);
INSERT INTO public.partiid VALUES (43, '2006-06-04 10:01:00', '2006-06-04 10:28:51', 147, 78, 2, 0, 270);
INSERT INTO public.partiid VALUES (42, '2005-03-04 13:01:00', '2005-03-04 13:22:58', 71, 79, 0, 2, 271);
INSERT INTO public.partiid VALUES (42, '2005-03-04 14:01:00', '2005-03-04 14:34:55', 73, 92, 1, 1, 272);
INSERT INTO public.partiid VALUES (42, '2005-03-04 13:01:00', '2005-03-04 13:29:10', 85, 84, 2, 0, 273);
INSERT INTO public.partiid VALUES (42, '2005-03-04 10:01:00', '2005-03-04 10:30:31', 89, 78, 1, 1, 274);
INSERT INTO public.partiid VALUES (43, '2006-06-04 14:01:00', '2006-06-04 14:28:01', 197, 89, 1, 1, 275);
INSERT INTO public.partiid VALUES (44, '2007-09-01 14:02:00', '2007-09-01 14:23:37', 198, 171, 1, 1, 276);
INSERT INTO public.partiid VALUES (47, '2010-10-14 13:03:00', '2010-10-14 13:21:13', 78, 71, 0, 2, 277);
INSERT INTO public.partiid VALUES (43, '2006-06-04 12:02:00', '2006-06-04 12:25:21', 149, 85, 1, 1, 278);
INSERT INTO public.partiid VALUES (42, '2005-03-04 13:01:00', '2005-03-04 13:21:49', 73, 86, 1, 1, 279);
INSERT INTO public.partiid VALUES (42, '2005-03-04 08:02:00', '2005-03-04 08:31:34', 89, 81, 1, 1, 280);
INSERT INTO public.partiid VALUES (44, '2007-09-01 11:01:00', '2007-09-01 11:23:30', 192, 173, 1, 1, 281);
INSERT INTO public.partiid VALUES (41, '2005-01-12 14:05:00', '2005-01-12 14:31:47', 78, 75, 0, 2, 282);
INSERT INTO public.partiid VALUES (44, '2007-09-01 16:01:00', '2007-09-01 16:33:38', 157, 78, 1, 1, 283);
INSERT INTO public.partiid VALUES (42, '2005-03-04 17:01:00', '2005-03-04 17:17:57', 93, 77, 0, 2, 284);
INSERT INTO public.partiid VALUES (43, '2006-06-04 08:01:00', '2006-06-04 08:27:38', 170, 153, 2, 0, 285);
INSERT INTO public.partiid VALUES (44, '2007-09-01 11:01:00', '2007-09-01 11:18:16', 191, 170, 0, 2, 286);
INSERT INTO public.partiid VALUES (44, '2007-09-01 10:01:00', '2007-09-01 10:22:31', 86, 71, 2, 0, 287);
INSERT INTO public.partiid VALUES (44, '2007-09-01 10:01:00', '2007-09-01 10:25:09', 201, 169, 1, 1, 288);
INSERT INTO public.partiid VALUES (44, '2007-09-01 14:01:00', '2007-09-01 14:21:26', 193, 157, 2, 0, 289);
INSERT INTO public.partiid VALUES (43, '2006-06-04 11:01:00', '2006-06-04 11:27:17', 168, 155, 0, 2, 290);
INSERT INTO public.partiid VALUES (43, '2006-06-04 08:01:00', '2006-06-04 08:21:21', 192, 156, 0, 2, 291);
INSERT INTO public.partiid VALUES (43, '2006-06-04 17:01:00', '2006-06-04 17:21:39', 174, 168, 0, 2, 292);
INSERT INTO public.partiid VALUES (43, '2006-06-04 09:01:00', '2006-06-04 09:38:35', 194, 147, 2, 0, 293);
INSERT INTO public.partiid VALUES (44, '2007-09-01 11:01:00', '2007-09-01 11:23:51', 82, 77, 1, 1, 294);
INSERT INTO public.partiid VALUES (42, '2005-03-04 16:03:00', '2005-03-04 16:17:55', 93, 75, 0, 2, 295);
INSERT INTO public.partiid VALUES (47, '2010-10-14 11:02:00', '2010-10-14 11:26:28', 82, 71, 2, 0, 296);
INSERT INTO public.partiid VALUES (44, '2007-09-01 08:01:00', '2007-09-01 08:32:47', 162, 90, 0, 2, 297);
INSERT INTO public.partiid VALUES (44, '2007-09-01 17:01:00', '2007-09-01 17:22:34', 198, 168, 1, 1, 298);
INSERT INTO public.partiid VALUES (42, '2005-03-04 17:01:00', '2005-03-04 17:30:53', 76, 85, 1, 1, 299);


--
-- TOC entry 5167 (class 0 OID 24916)
-- Dependencies: 232
-- Data for Name: riigid; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.riigid VALUES (12, 'Albania', 'Tirana', 2876591, 28748, 15.290);
INSERT INTO public.riigid VALUES (23, 'Armenia', 'Yerevan', 2924816, 29743, 11.550);
INSERT INTO public.riigid VALUES (6, 'Azerbaijan', 'Baku', 9911646, 86600, 39.210);
INSERT INTO public.riigid VALUES (32, 'Australia', 'Canberra', 25023700, 7692024, 1500.000);
INSERT INTO public.riigid VALUES (4, 'Austria', 'Vienna', 8823054, 83897, 477.670);
INSERT INTO public.riigid VALUES (16, 'Belarus', 'Minsk', 9494800, 207595, 59.000);
INSERT INTO public.riigid VALUES (13, 'Belgium', 'Brussels', 11358357, 30528, 562.230);
INSERT INTO public.riigid VALUES (18, 'Bulgaria', 'Sofia', 7050034, 110993, 55.950);
INSERT INTO public.riigid VALUES (20, 'Croatia', 'Zagreb', 4154200, 56594, 61.060);
INSERT INTO public.riigid VALUES (14, 'Czech Republic', 'Prague', 10610947, 78866, 238.000);
INSERT INTO public.riigid VALUES (26, 'Cyprus', 'Nicosia  ', 1170125, 9251, 19.810);
INSERT INTO public.riigid VALUES (5, 'Denmark', 'Copenhagen', 5785864, 42933, 340.980);
INSERT INTO public.riigid VALUES (17, 'Estonia', 'Tallinn', 1319133, 45227, 30.820);
INSERT INTO public.riigid VALUES (22, 'Finland', 'Helsinki', 5509717, 338424, 289.560);
INSERT INTO public.riigid VALUES (42, 'France', 'Paris', 67186638, 640679, 2583.000);
INSERT INTO public.riigid VALUES (33, 'Georgia', 'Tbilisi', 3718200, 69700, 15.020);
INSERT INTO public.riigid VALUES (7, 'Germany', 'Berlin', 82800000, 357386, 3685.000);
INSERT INTO public.riigid VALUES (21, 'Greece', 'Athens', 10768477, 131957, 221.570);
INSERT INTO public.riigid VALUES (36, 'Hungary', 'Budapest', 9797561, 93030, 163.540);
INSERT INTO public.riigid VALUES (11, 'Iceland', 'Reykjavík', 350710, 102775, 25.000);
INSERT INTO public.riigid VALUES (25, 'Ireland', 'Dublin', 4792500, 70273, 385.000);
INSERT INTO public.riigid VALUES (10, 'Israel', 'Jerusalem', 8896680, 20770, 373.750);
INSERT INTO public.riigid VALUES (43, 'Italy', 'Rome', 60483973, 301340, 2181.000);
INSERT INTO public.riigid VALUES (37, 'Latvia', 'Riga', 1925700, 64589, 30.180);
INSERT INTO public.riigid VALUES (15, 'Lithuania', 'Vilnius', 2800667, 65300, 54.350);
INSERT INTO public.riigid VALUES (19, 'North Macedonia', 'Skopje', 2103721, 25713, 12.290);
INSERT INTO public.riigid VALUES (35, 'Malta', 'Valletta', 475700, 316, 13.330);
INSERT INTO public.riigid VALUES (30, 'Moldova', 'Chișinău', 2998235, 33846, 9.200);
INSERT INTO public.riigid VALUES (38, 'Montenegro', 'Podgorica', 642550, 13812, 4.020);
INSERT INTO public.riigid VALUES (31, 'Netherlands', 'Amsterdam', 17215830, 41543, 945.330);
INSERT INTO public.riigid VALUES (8, 'Norway', 'Oslo', 5295719, 385203, 443.000);
INSERT INTO public.riigid VALUES (34, 'Poland', 'Warsaw', 38433600, 312696, 614.190);
INSERT INTO public.riigid VALUES (1, 'Portugal', 'Lisbon', 10291027, 92212, 279.770);
INSERT INTO public.riigid VALUES (27, 'Romania', 'Bucharest', 19638000, 238397, 204.940);
INSERT INTO public.riigid VALUES (9, 'Russia', 'Moscow', 144526636, 17098246, 1719.000);
INSERT INTO public.riigid VALUES (29, 'San Marino', 'San Marino', 33537, 61, 1.060);
INSERT INTO public.riigid VALUES (28, 'Serbia', 'Belgrade', 7040272, 88361, 42.380);
INSERT INTO public.riigid VALUES (39, 'Slovenia', 'Ljubljana', 2066880, 20273, 56.930);
INSERT INTO public.riigid VALUES (40, 'Spain', 'Madrid', 46700000, 505990, 1506.000);
INSERT INTO public.riigid VALUES (3, 'Sweden', 'Stockholm', 10161797, 450295, 601.000);
INSERT INTO public.riigid VALUES (24, 'Switzerland', 'Bern', 8401120, 41285, 681.000);
INSERT INTO public.riigid VALUES (2, 'Ukraine', 'Kiev', 42418235, 603628, 104.000);
INSERT INTO public.riigid VALUES (41, 'United Kingdom', 'London', 66040229, 242495, 2624.000);
INSERT INTO public.riigid VALUES (44, 'Brazil', 'Brasília', 209129000, 8515767, 2139.000);
INSERT INTO public.riigid VALUES (45, 'Bosnia and Herzegovina', 'Sarajevo', 3856181, 51129, 18.060);
INSERT INTO public.riigid VALUES (46, 'Turkey', 'Ankara', 80810525, 783356, 909.000);
INSERT INTO public.riigid VALUES (47, 'Canada', 'Ottawa', 37067011, 9984670, 1798.000);
INSERT INTO public.riigid VALUES (48, 'South Korea', 'Seoul', 51446201, 100210, 1693.000);
INSERT INTO public.riigid VALUES (49, 'Kyrgyzstan', 'Bishkek', 6019480, 199951, 7.060);
INSERT INTO public.riigid VALUES (50, 'Turkmenistan', 'Ashgabat', 5662544, 491210, 42.360);
INSERT INTO public.riigid VALUES (51, 'Malaysia', 'Kuala Lumpur', 32049700, 330803, 364.920);
INSERT INTO public.riigid VALUES (52, 'United States of America', 'Washington', 325719178, 9833520, 19390.000);
INSERT INTO public.riigid VALUES (53, 'Slovakia', 'Bratislava', 5435343, 49035, 111.000);
INSERT INTO public.riigid VALUES (54, 'Kosovo', 'Pristina', 1920079, 10908, 7.070);
INSERT INTO public.riigid VALUES (55, 'Guatemala', 'Guatemala City', 17263239, 108889, 82.360);
INSERT INTO public.riigid VALUES (56, 'Iran', 'Tehran', 81672300, 1648195, 438.000);
INSERT INTO public.riigid VALUES (57, 'Indonesia', 'Jakarta', 261115456, 1904569, 1074.000);
INSERT INTO public.riigid VALUES (58, 'Kenya', 'Nairobi', 49125325, 580367, 85.980);
INSERT INTO public.riigid VALUES (59, 'Andorra', 'Andorra la Vella', 77281, 468, 3.250);
INSERT INTO public.riigid VALUES (60, 'India', 'New Delhi', 1324171354, 3287263, 2848.000);
INSERT INTO public.riigid VALUES (61, 'Tajikistan', 'Dushanbe', 9537645, 143100, 7.350);
INSERT INTO public.riigid VALUES (62, 'Suriname', 'Paramaribo', 575990, 163821, 4.110);
INSERT INTO public.riigid VALUES (63, 'Congo', 'Kinshasa', 105044646, 2345409, 46.120);
INSERT INTO public.riigid VALUES (64, 'Cuba', 'Havana', 11181595, 109884, 107.350);


--
-- TOC entry 5169 (class 0 OID 24923)
-- Dependencies: 234
-- Data for Name: tooted; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tooted VALUES (1, 'Tugitool');


--
-- TOC entry 5171 (class 0 OID 24928)
-- Dependencies: 236
-- Data for Name: turniirid; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.turniirid VALUES (41, 'Kolme klubi kohtumine', '2005-01-12', '2005-01-12', 9);
INSERT INTO public.turniirid VALUES (47, 'Plekkkarikas 2010', '2010-10-14', '2010-10-14', 3);
INSERT INTO public.turniirid VALUES (42, 'Tartu lahtised meistrivõistlused 2005', '2005-03-04', '2005-03-17', 5);
INSERT INTO public.turniirid VALUES (43, 'Viljandi lahtised meistrivõistlused 2006', '2006-06-04', '2006-06-04', 8);
INSERT INTO public.turniirid VALUES (44, 'Eesti meistrivõistlused 2007', '2007-09-01', '2007-09-01', 10);
INSERT INTO public.turniirid VALUES (1, 'Tartu Meister', '2026-02-02', '2026-02-04', 5);


--
-- TOC entry 5185 (class 0 OID 0)
-- Dependencies: 220
-- Name: asulad_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.asulad_id_seq', 10, true);


--
-- TOC entry 5186 (class 0 OID 0)
-- Dependencies: 223
-- Name: isikud_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.isikud_id_seq', 21, true);


--
-- TOC entry 5187 (class 0 OID 0)
-- Dependencies: 225
-- Name: klubid_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.klubid_id_seq', 4, true);


--
-- TOC entry 5188 (class 0 OID 0)
-- Dependencies: 231
-- Name: partiid_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.partiid_id_seq', 299, true);


--
-- TOC entry 5189 (class 0 OID 0)
-- Dependencies: 233
-- Name: riigid_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.riigid_id_seq', 1, false);


--
-- TOC entry 5190 (class 0 OID 0)
-- Dependencies: 235
-- Name: tooted_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tooted_id_seq', 1, true);


--
-- TOC entry 5191 (class 0 OID 0)
-- Dependencies: 237
-- Name: turniirid_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.turniirid_id_seq', 1, true);


--
-- TOC entry 4961 (class 2606 OID 24985)
-- Name: asulad asulad_nimi_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asulad
    ADD CONSTRAINT asulad_nimi_key UNIQUE (nimi);


--
-- TOC entry 4963 (class 2606 OID 24987)
-- Name: asulad asulad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asulad
    ADD CONSTRAINT asulad_pkey PRIMARY KEY (id);


--
-- TOC entry 4965 (class 2606 OID 24989)
-- Name: inimesed inimesed_isikukood_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inimesed
    ADD CONSTRAINT inimesed_isikukood_key UNIQUE (isikukood);


--
-- TOC entry 4967 (class 2606 OID 24991)
-- Name: inimesed inimesed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inimesed
    ADD CONSTRAINT inimesed_pkey PRIMARY KEY (eesnimi, perenimi, synnipaev);


--
-- TOC entry 4969 (class 2606 OID 24993)
-- Name: isikud isikud_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isikud
    ADD CONSTRAINT isikud_pk PRIMARY KEY (id);


--
-- TOC entry 4975 (class 2606 OID 24995)
-- Name: klubid klubid_nimi_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.klubid
    ADD CONSTRAINT klubid_nimi_key UNIQUE (nimi);


--
-- TOC entry 4977 (class 2606 OID 24997)
-- Name: klubid klubid_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.klubid
    ADD CONSTRAINT klubid_pk PRIMARY KEY (id);


--
-- TOC entry 4971 (class 2606 OID 24999)
-- Name: isikud nimi_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isikud
    ADD CONSTRAINT nimi_unique UNIQUE (eesnimi, perenimi);


--
-- TOC entry 4979 (class 2606 OID 25001)
-- Name: partiid partiid_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiid
    ADD CONSTRAINT partiid_pk PRIMARY KEY (id);


--
-- TOC entry 4981 (class 2606 OID 25003)
-- Name: riigid riigid_nimi_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.riigid
    ADD CONSTRAINT riigid_nimi_key UNIQUE (nimi);


--
-- TOC entry 4983 (class 2606 OID 25005)
-- Name: riigid riigid_pealinn_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.riigid
    ADD CONSTRAINT riigid_pealinn_key UNIQUE (pealinn);


--
-- TOC entry 4985 (class 2606 OID 25007)
-- Name: riigid riigid_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.riigid
    ADD CONSTRAINT riigid_pkey PRIMARY KEY (id);


--
-- TOC entry 4987 (class 2606 OID 25009)
-- Name: turniirid turniirid_nimi_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.turniirid
    ADD CONSTRAINT turniirid_nimi_key UNIQUE (nimi);


--
-- TOC entry 4989 (class 2606 OID 25011)
-- Name: turniirid turniirid_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.turniirid
    ADD CONSTRAINT turniirid_pk PRIMARY KEY (id);


--
-- TOC entry 4973 (class 2606 OID 25013)
-- Name: isikud un_isikukood; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isikud
    ADD CONSTRAINT un_isikukood UNIQUE (isikukood);


--
-- TOC entry 4990 (class 2606 OID 25014)
-- Name: isikud fk_isikud2klubid; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.isikud
    ADD CONSTRAINT fk_isikud2klubid FOREIGN KEY (klubis) REFERENCES public.klubid(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4991 (class 2606 OID 25019)
-- Name: klubid fk_klubi_2_asula; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.klubid
    ADD CONSTRAINT fk_klubi_2_asula FOREIGN KEY (asula) REFERENCES public.asulad(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4992 (class 2606 OID 25024)
-- Name: partiid fk_partiid2must; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiid
    ADD CONSTRAINT fk_partiid2must FOREIGN KEY (must) REFERENCES public.isikud(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4993 (class 2606 OID 25029)
-- Name: partiid fk_partiid2turniirid; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiid
    ADD CONSTRAINT fk_partiid2turniirid FOREIGN KEY (turniir) REFERENCES public.turniirid(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4994 (class 2606 OID 25034)
-- Name: partiid fk_partiid2valge; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partiid
    ADD CONSTRAINT fk_partiid2valge FOREIGN KEY (valge) REFERENCES public.isikud(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4995 (class 2606 OID 25039)
-- Name: turniirid fk_turniir_2_asula; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.turniirid
    ADD CONSTRAINT fk_turniir_2_asula FOREIGN KEY (asula) REFERENCES public.asulad(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5164 (class 0 OID 24903)
-- Dependencies: 229 5174
-- Name: mv_edetabelid; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: -
--

REFRESH MATERIALIZED VIEW public.mv_edetabelid;


--
-- TOC entry 5165 (class 0 OID 24910)
-- Dependencies: 230 5174
-- Name: mv_partiide_arv_valgetega; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: -
--

REFRESH MATERIALIZED VIEW public.mv_partiide_arv_valgetega;


-- Completed on 2026-04-26 15:03:36

--
-- PostgreSQL database dump complete
--

\unrestrict xB13m2yKqRTRvbLOvtfBckUn0zBc2uTGHxdhiIC6mvo4Z6YSSvdh9Q69QsJtAc5

