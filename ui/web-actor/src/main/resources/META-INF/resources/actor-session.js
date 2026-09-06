/**
 * Authenticated actor session rooted at the HAL actor profile.
 * Bootstrap still uses AppConfig.API_PATHS.ACTOR_PROFILE; subsequent actions follow _links.
 */
const ActorSession = {
  _profile: null,
  _links: null,
  _actorId: null,

  /**
   * Loads (or returns cached) HAL actor profile for the current user.
   * @param {boolean} [force=false] - When true, bypasses cache
   * @returns {Promise<object>} Actor profile payload including _links
   */
  async load(force = false) {
    const actorId = AuthUtils.getCandidateId();
    if (!actorId) {
      throw new Error('Unable to determine actor identity');
    }

    if (!force && this._profile && this._actorId === actorId) {
      return this._profile;
    }

    const actorPath = AppConfig.API_PATHS.ACTOR_PROFILE(actorId);
    const result = await ApiClient.request(actorPath, {
      method: 'GET',
      headers: {
        Accept: 'application/hal+json'
      }
    });

    this._actorId = actorId;
    this._profile = result.data || null;
    this._links = (this._profile && this._profile._links) || {};

    if (this._profile && this._profile.username) {
      localStorage.setItem('username', this._profile.username);
    }

    return this._profile;
  },

  /**
   * Returns href for a HAL rel from the last loaded profile.
   * @param {string} rel - Link relation name
   * @returns {string|null}
   */
  link(rel) {
    const entry = this._links && this._links[rel];
    return entry && entry.href ? entry.href : null;
  },

  /**
   * @returns {object|null} Cached profile payload
   */
  profile() {
    return this._profile;
  },

  clear() {
    this._profile = null;
    this._links = null;
    this._actorId = null;
  }
};
