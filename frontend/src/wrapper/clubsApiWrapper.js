import apiClient from "@/wrapper/axiosClient.js";

export async function fetchAllClubs() {
  try {
    const response = await apiClient.get("/clubs");
    return mapClubsData(response.data);
  } catch (error) {
    console.error('Error fetching clubs', error);
  }
}

export async function fetchClubById(clubId) {
  try {
    const response = await apiClient.get(`/clubs/${clubId}`);
    return mapClubData(response.data);
  } catch (error) {
    console.error('Error fetching club', error);
  }
}

export async function addClub(club) {
  try {
    await apiClient.post('/clubs', club);
  } catch (error) {
    console.error('Error adding club', error);
  }
}

export async function fetchTopPlayersInClub(clubId) {
  try {
    const response = await apiClient.get(`/clubs/${clubId}/top-players`);
    return response.data.map(player => ({
      name: player.mangija,
      elo: player.elo
    }));
  } catch (error) {
    console.error('Error fetching top players in club', error);
    return [];
  }
}

export async function fetchTopClubs(limit) {
  try {
    const response = await apiClient.get( `/clubs/top/${limit}`);
    return mapClubsData(response.data);
  } catch (error) {
    console.error('Error fetching top clubs', error);
  }
}

export async function removeClub(clubId) {
  try {
    await apiClient.delete(`/clubs/${clubId}`);
  } catch (error) {
    console.error('Error deleting club', error);
  }
}

function mapClubsData(rawClubData) {
  return rawClubData.map(club => {
    return mapClubData(club)
  });
}

function mapClubData(club) {
  return {
    id: club.id,
    name: club.nimi,
    location: club.asukoht,
    membersCount: club.members,
    averageRating: club.average_rating == null ? 0 : club.average_rating
  };
}
