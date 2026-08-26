/* global axios */
import ApiClient from './ApiClient';

class AccountLogoAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  get accountUrl() {
    return `${this.apiVersion}/accounts/${this.accountIdFromRoute}`;
  }

  updateLogo(blobId) {
    return axios.patch(`${this.accountUrl}/update_logo`, {
      blob_id: blobId,
    });
  }

  updateLogoDark(blobId) {
    return axios.patch(`${this.accountUrl}/update_logo_dark`, {
      blob_id: blobId,
    });
  }

  updateLogoThumbnail(blobId) {
    return axios.patch(`${this.accountUrl}/update_logo_thumbnail`, {
      blob_id: blobId,
    });
  }

  deleteLogo() {
    return axios.delete(`${this.accountUrl}/delete_logo`);
  }

  deleteLogoDark() {
    return axios.delete(`${this.accountUrl}/delete_logo_dark`);
  }

  deleteLogoThumbnail() {
    return axios.delete(`${this.accountUrl}/delete_logo_thumbnail`);
  }
}

export default new AccountLogoAPI();
