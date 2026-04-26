const SELECT_MATCH_BY_ID = `
  SELECT
    p.id,
    p.turniir,
    p.algushetk,
    p.lopphetk,
    valge.id AS valge_id,
    valge.eesnimi AS valge_eesnimi,
    valge.perenimi AS valge_perenimi,
    valge.klubi AS valge_klubi,
    must.id AS must_id,
    must.eesnimi AS must_eesnimi,
    must.perenimi AS must_perenimi,
    must.klubi AS must_klubi,
    CASE
      WHEN valge_tulemus = 2 THEN 'Valge'
      WHEN must_tulemus = 2 THEN 'Must'
      ELSE 'Viik'
    END AS voitja
FROM
    partiid p
LEFT JOIN (
    SELECT
        i.id,
        i.eesnimi,
        i.perenimi,
        k.nimi AS klubi
    FROM
        isikud i
    LEFT JOIN
        klubid k ON i.klubis = k.id
) valge ON valge.id = p.valge
LEFT JOIN (
    SELECT
        i.id,
        i.eesnimi,
        i.perenimi,
        k.nimi AS klubi
    FROM
        isikud i
    LEFT JOIN
        klubid k ON i.klubis = k.id
) must ON must.id = p.must
`;

function getAddOrUpdateMatchQuery(isUpdate) {
    let query;
    if (isUpdate) {
        query = `
        UPDATE partiid
        SET valge = $2, must = $3, algushetk = $4, lopphetk = $5, valge_tulemus = $6, must_tulemus = $7
        WHERE id = $1
        `;
    } else {
        query = `
        INSERT INTO partiid (turniir, valge, must, algushetk, lopphetk, valge_tulemus, must_tulemus)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        `;
    }
    return query;
}

const SELECT_ONGOING_MATCHES = `
    SELECT
    p.id,
    t.nimi AS turniir,
    p.algushetk,
    valge.eesnimi AS valge_eesnimi,
    valge.perenimi AS valge_perenimi,
    valge.klubi AS valge_klubi,
    must.eesnimi AS must_eesnimi,
    must.perenimi AS must_perenimi,
    must.klubi AS must_klubi
    FROM partiid p
    LEFT JOIN (
    SELECT
        i.id,
        i.eesnimi,
        i.perenimi,
        k.nimi AS klubi
    FROM
        isikud i
    LEFT JOIN
        klubid k ON i.klubis = k.id
    ) valge ON valge.id = p.valge
    LEFT JOIN (
        SELECT
            i.id,
            i.eesnimi,
            i.perenimi,
            k.nimi AS klubi
        FROM
            isikud i
        LEFT JOIN
            klubid k ON i.klubis = k.id
    ) must ON must.id = p.must
    LEFT JOIN turniirid t ON p.turniir = t.id
    WHERE p.lopphetk IS NULL
`;

const SELECT_ALL_LOCATIONS = `
        SELECT * FROM asulad a
`;

const SELECT_ALL_PLAYERS = `
      SELECT i.id, i.eesnimi, i.perenimi, k.nimi AS klubi, i.synniaeg, i.sugu, i.ranking FROM isikud i
        LEFT JOIN klubid k ON i.klubis = k.id
`;

const SELECT_PLAYER_BY_ID = `
      SELECT i.id, i.eesnimi, i.perenimi, k.nimi AS klubi, i.synniaeg, i.sugu, i.ranking, i.isikukood FROM isikud i
        LEFT JOIN klubid k ON i.klubis = k.id
        WHERE i.id = $1
`;

const SELECT_ALL_PLAYERS_IN_CLUB = `
      SELECT i.id, i.eesnimi, i.perenimi, k.nimi AS klubi, i.synniaeg, i.sugu, i.ranking FROM isikud i
        LEFT JOIN KLUBID k ON i.klubis = k.id
        WHERE i.klubis = $1
`;

const SELECT_PLAYER_STATISTICS = `
    SELECT
    COUNT(*) AS match_count,
    SUM(
      CASE
        WHEN (p.valge = $1 AND p.valge_tulemus = 2)
          OR (p.must = $1 AND p.must_tulemus = 2)
        THEN 1 ELSE 0
      END
    ) AS win_count,
    SUM(
      CASE
        WHEN p.valge = $1 THEN 1 ELSE 0
      END
    ) AS white_match_count,
    SUM(
      CASE
        WHEN p.valge = $1 AND p.valge_tulemus = 2
        THEN 1 ELSE 0
      END
    ) AS white_win_count,
    SUM(
      CASE
        WHEN p.must = $1 THEN 1 ELSE 0
      END
    ) AS black_match_count,
    SUM(
      CASE
        WHEN p.must = $1 AND p.must_tulemus = 2
        THEN 1 ELSE 0
      END
    ) AS black_win_count,
    (SELECT (p.lopphetk - p.algushetk) AS duration FROM partiid p
     WHERE p.valge = $1 or p.must = $1
     ORDER by duration DESC
     LIMIT 1 ) AS longest_match
    FROM partiid p
    WHERE p.valge = $1
       OR p.must = $1;
`;

const SELECT_TOP_PLAYERS = `
        SELECT * FROM isikud
        WHERE ranking IS NOT NULL
        ORDER BY ranking DESC
        LIMIT $1
`;

function getAddOrUpdatePlayerQuery(isUpdate) {
    if (isUpdate) {
        return `
        UPDATE isikud
        SET (eesnimi, perenimi, klubis, synniaeg, sugu, ranking) = 
        ($1,
            $2,
            (SELECT id FROM klubid WHERE nimi = $3),
            $4,
            $5,
            $6)
        WHERE id = $7
        `
    } else {
        return `
        INSERT INTO isikud (eesnimi, perenimi, klubis, synniaeg, sugu, ranking)
        VALUES ($1,
            $2,
            (SELECT id FROM klubid WHERE nimi = $3),
            $4,
            $5,
            $6)
        `
    }
}

const DELETE_PLAYER = `
    DELETE FROM isikud i
    WHERE i.id = $1
`

const SELECT_ALL_TOURNAMENTS = `
  SELECT t.id, t.nimi, t.alguskuupaev, t.loppkuupaev, a.nimi AS toimumiskoht FROM turniirid t
  LEFT JOIN asulad a ON t.asula = a.id
  ORDER BY loppkuupaev DESC
`;

const SELECT_ONGOING_TOURNAMENTS = `
  SELECT t.id, t.nimi, t.alguskuupaev, t.loppkuupaev, a.nimi AS toimumiskoht FROM turniirid t
  LEFT JOIN asulad a ON t.asula = a.id
  WHERE loppkuupaev > CURRENT_DATE
`;

const SELECT_TOURNAMENT_BY_ID = `
  SELECT t.id, t.nimi, t.alguskuupaev, t.loppkuupaev, a.nimi AS toimumiskoht FROM turniirid t
  LEFT JOIN asulad a ON t.asula = a.id
  WHERE t.id = $1
`;

function getAddOrUpdateTournamentQuery(isUpdate) {
    if (isUpdate) {
        return `
        UPDATE turniirid
        SET (nimi, asula, alguskuupaev, loppkuupaev) =
            ($1,
            (SELECT id FROM asulad WHERE nimi = $2),
            $3,
            $4)
        WHERE id = ($5)
        `
    } else {
        return `
          INSERT INTO turniirid (nimi, asula, alguskuupaev, loppkuupaev)
          VALUES ($1,
                 (SELECT id FROM asulad WHERE nimi = $2),
                 $3,
                 $4)
        `
    }
}

const DELETE_TOURNAMENT = `
    DELETE FROM turniirid t
    WHERE t.id = $1
`

const SELECT_ALL_CLUBS = `
    SELECT k.*, COUNT(i.id) as members, ROUND(AVG(i.ranking), 1) as average_rating
    FROM klubid k
    LEFT JOIN isikud i ON k.id = i.klubis
    GROUP BY k.id
`;

const SELECT_CLUB_BY_ID = `
    SELECT k.nimi, a.nimi AS asukoht, COUNT(i.id) AS members, ROUND(AVG(i.ranking), 1) AS average_rating
    FROM klubid k
    LEFT JOIN isikud i ON k.id = i.klubis
    LEFT JOIN asulad a ON k.asula = a.id
    WHERE k.id = $1
    GROUP BY k.nimi, a.nimi
`;

const SELECT_TOP_PLAYERS_IN_CLUB = `
    SELECT mangija, elo
    FROM f_klubiparimad($1)
`;

const SELECT_TOP_CLUBS = `
    SELECT k.nimi, ROUND(AVG(i.ranking), 1) as average_rating
    FROM klubid k
    LEFT JOIN isikud i ON k.id = i.klubis
    GROUP BY k.nimi
    HAVING AVG(i.ranking) IS NOT NULL
    ORDER BY average_rating DESC
    LIMIT $1
`;

function getAddOrUpdateClubQuery(isUpdate) {
    if (isUpdate) {
        return `
        UPDATE klubid
        SET (nimi, asula) = 
            ($1,
            (SELECT id FROM asulad WHERE nimi = $2))
        WHERE id = $3
        `
    } else {
        return `
            INSERT INTO klubid (nimi, asula)
            VALUES             
                ($1,
                (SELECT id FROM asulad WHERE nimi = $2))
            RETURNING id
        `
    }
}

const DELETE_CLUB = `
    DELETE FROM klubid k
    WHERE k.id = $1
`

module.exports = {
    SELECT_MATCH_BY_ID,
    getAddOrUpdateMatchQuery,
    SELECT_ONGOING_MATCHES,
    SELECT_ALL_LOCATIONS,
    SELECT_ALL_PLAYERS,
    SELECT_PLAYER_BY_ID,
    SELECT_ALL_PLAYERS_IN_CLUB,
    SELECT_PLAYER_STATISTICS,
    SELECT_TOP_PLAYERS,
    getAddOrUpdatePlayerQuery,
    DELETE_PLAYER,
    SELECT_ALL_TOURNAMENTS,
    SELECT_ONGOING_TOURNAMENTS,
    SELECT_TOURNAMENT_BY_ID,
    getAddOrUpdateTournamentQuery,
    DELETE_TOURNAMENT,
    SELECT_ALL_CLUBS,
    SELECT_CLUB_BY_ID,
    SELECT_TOP_PLAYERS_IN_CLUB,
    SELECT_TOP_CLUBS,
    getAddOrUpdateClubQuery,
    DELETE_CLUB,
};
