/* global axios */
import ApiClient from './ApiClient';

class AccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  get accountUrl() {
    return `${this.apiVersion}/accounts/${this.accountIdFromRoute}`;
  }

  get() {
    return axios.get(this.accountUrl);
  }

  update(idOrData, maybeData) {
    const data = maybeData !== undefined ? maybeData : idOrData;
    return axios.patch(this.accountUrl, data);
  }

  delete() {
    return axios.delete(this.accountUrl);
  }

  createAccount(data) {
    return axios.post(`${this.apiVersion}/accounts`, data);
  }

  async getCacheKeys() {
    const response = await axios.get(
      `${this.accountUrl}/cache_keys`
    );
    return response.data.cache_keys;
  }
}

export default new AccountAPI();
