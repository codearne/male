const {pool} = require("../database")
const {
    SELECT_ALL_CLUBS,
    SELECT_CLUB_BY_ID,
    SELECT_TOP_PLAYERS_IN_CLUB,
    SELECT_TOP_CLUBS,
    getAddOrUpdateClubQuery,
    DELETE_CLUB
} = require("./queries");

const getAllClubs = (req, res) => {
    console.log("IN - Get all clubs request")

    pool.query(SELECT_ALL_CLUBS, (err, results) => {
        if (err) {
            console.error(err)
            return res.status(500).send({
                message: "Error while reading all clubs",
                error: err
            })
        }

        console.log("OUT - Get all clubs result: " + JSON.stringify(results.rows))
        res.status(200).send(results.rows)
    })
}

const getClubById = (req, res) => {
    const id = parseInt(req.params.id)
    console.log(`IN - Get club(id=${id}) request`)

    pool.query(SELECT_CLUB_BY_ID, [id], (err, results) => {
        if (err) {
            console.error(err)
            return res.status(500).send({
                message: "Error while reading club with id: " + id,
                error: err
            })
        }

        console.log(`OUT - Get club(id=${id}) result: ${JSON.stringify(results.rows[0])}`)
        res.status(200).send(results.rows[0])
    })
}

const getTopClubs = (req, res) => {
    const limit = parseInt(req.params.limit)
    console.log(`IN - Get top clubs (limit=${limit})`)

    pool.query(SELECT_TOP_CLUBS, [limit], (err, results) => {
        if (err) {
            console.error(err)
            return res.status(500).send({
                message: "Error while reading top clubs:",
                error: err
            })
        }
        console.log("OUT - Get top clubs" + JSON.stringify(results.rows))
        res.status(200).send(results.rows)
    })
}

const getTopPlayersInClub = (req, res) => {
    const id = parseInt(req.params.id)
    console.log(`IN - Get top players in club(id=${id}) request`)

    pool.query(SELECT_TOP_PLAYERS_IN_CLUB, [id], (err, results) => {
        if (err) {
            console.error(err)
            return res.status(500).send({
                message: "Error while reading top players for club with id: " + id,
                error: err
            })
        }

        console.log(`OUT - Get top players in club(id=${id}) result: ${JSON.stringify(results.rows)}`)
        res.status(200).send(results.rows)
    })
}

const addClub = (req, res) => {
    const {name, location, isUpdate, clubId} = req.body
    const update = JSON.parse(isUpdate)
    console.log(`IN: Add club request: club(name=${name}, location=${location})`)

    const query = getAddOrUpdateClubQuery(update)
    let values = [name, location]
    if (update) {
        values.push(clubId)
    }

    pool.query(query, values, (err, results) => {
        if (err) {
            console.error(err)
            return res.status(500).send({
                message: "Error while adding club",
                error: err
            })
        }

        console.log(`OUT - Add club result: ${JSON.stringify(results.rows[0])}`)
        res.status(200).send(results.rows[0])
    })
}

const deleteClub = (req, res) => {
    const clubId = parseInt(req.params.clubId)
    console.log(`IN - Delete club(id=${clubId}) request`)

    pool.query(DELETE_CLUB, [clubId], (err, results) => {
        if (err) {
            console.error(err)
            return res.status(500).send({
                message: `Error while deleting club(id=${clubId})`,
                error: err
            })
        }

        console.log(`OUT - Delete club(id=${clubId}) result: ${JSON.stringify(results.rows)}`)
        res.status(200).send(results.rows)
    })
}

module.exports = { getAllClubs, getClubById, getTopPlayersInClub, addClub, getTopClubs, deleteClub }
