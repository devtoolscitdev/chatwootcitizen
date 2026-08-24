<script>
import { useVuelidate } from '@vuelidate/core';
import { required, url } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';

import NextButton from 'dashboard/components-next/button/Button.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';

export default {
  components: {
    NextButton,
    ToggleSwitch,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    mode: {
      type: String,
      default: 'create',
    },
    selectedAppData: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['close'],
  setup() {
    return { v$: useVuelidate() };
  },
  validations: {
    app: {
      title: { required },
      content: {
        type: { required },
        url: { required, url },
      },
    },
  },
  data() {
    return {
      isLoading: false,
      app: {
        title: '',
        show_on_sidebar: false,
        icon: 'i-lucide-layout-grid',
        position: 0,
        sidebar_placement: 'main',
        content: {
          type: 'frame',
          url: '',
        },
      },
      availableIcons: [
        { label: 'Kanban / Colunas', value: 'i-lucide-columns-3' },
        { label: 'ERP / Camadas (Odoo)', value: 'i-lucide-layers' },
        { label: 'Caixas / Estoque', value: 'i-lucide-boxes' },
        { label: 'Carrinho / Vendas', value: 'i-lucide-shopping-cart' },
        { label: 'Banco de Dados', value: 'i-lucide-database' },
        { label: 'Gráficos / BI', value: 'i-lucide-bar-chart-3' },
        { label: 'Website / Link', value: 'i-lucide-globe' },
        { label: 'Padrão / Grid', value: 'i-lucide-layout-grid' },
      ],
    };
  },
  computed: {
    header() {
      return this.$t(`INTEGRATION_SETTINGS.DASHBOARD_APPS.${this.mode}.HEADER`);
    },
    submitButtonLabel() {
      return this.$t(
        `INTEGRATION_SETTINGS.DASHBOARD_APPS.${this.mode}.FORM_SUBMIT`
      );
    },
  },
  mounted() {
    if (this.mode === 'UPDATE' && this.selectedAppData) {
      this.app.title = this.selectedAppData.title;
      this.app.content = this.selectedAppData.content[0];
      this.app.show_on_sidebar = this.selectedAppData.show_on_sidebar ?? false;
      this.app.icon = this.selectedAppData.icon || 'i-lucide-layout-grid';
      this.app.position = this.selectedAppData.position || 0;
      this.app.sidebar_placement = this.selectedAppData.sidebar_placement || 'main';
    }
  },
  methods: {
    closeModal() {
      // Reset the data once closed
      this.app = {
        title: '',
        show_on_sidebar: false,
        icon: 'i-lucide-layout-grid',
        position: 0,
        sidebar_placement: 'main',
        content: { type: 'frame', url: '' },
      };
      this.$emit('close');
    },
    async submit() {
      try {
        this.v$.$touch();
        if (this.v$.$invalid) {
          return;
        }

        const action = this.mode.toLowerCase();
        const payload = {
          title: this.app.title,
          show_on_sidebar: this.app.show_on_sidebar,
          icon: this.app.icon,
          position: Number(this.app.position) || 0,
          sidebar_placement: this.app.sidebar_placement,
          content: [this.app.content],
        };

        if (action === 'update') {
          payload.id = this.selectedAppData.id;
        }

        this.isLoading = true;
        await this.$store.dispatch(`dashboardApps/${action}`, payload);
        useAlert(
          this.$t(
            `INTEGRATION_SETTINGS.DASHBOARD_APPS.${this.mode}.API_SUCCESS`
          )
        );
        this.closeModal();
      } catch (err) {
        useAlert(
          this.$t(`INTEGRATION_SETTINGS.DASHBOARD_APPS.${this.mode}.API_ERROR`)
        );
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <woot-modal :show="show" :on-close="closeModal">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="header" />
      <form class="w-full" @submit.prevent="submit">
        <woot-input
          v-model="app.title"
          :class="{ error: v$.app.title.$error }"
          class="w-full"
          :label="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.TITLE_LABEL')"
          :placeholder="
            $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.TITLE_PLACEHOLDER')
          "
          :error="
            v$.app.title.$error
              ? $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.TITLE_ERROR')
              : null
          "
          data-testid="app-title"
          @input="v$.app.title.$touch"
          @blur="v$.app.title.$touch"
        />
        <woot-input
          v-model="app.content.url"
          :class="{ error: v$.app.content.url.$error }"
          class="w-full"
          :label="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.URL_LABEL')"
          :placeholder="
            $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.URL_PLACEHOLDER')
          "
          :error="
            v$.app.content.url.$error
              ? $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.URL_ERROR')
              : null
          "
          data-testid="app-url"
          @input="v$.app.content.url.$touch"
          @blur="v$.app.content.url.$touch"
        />
        <div class="flex items-center w-full gap-3 py-2">
          <label
            class="text-sm text-n-slate-12 cursor-pointer"
            for="show-on-sidebar"
          >
            {{
              $t(
                'INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.SHOW_ON_SIDEBAR_LABEL'
              )
            }}
          </label>
          <ToggleSwitch id="show-on-sidebar" v-model="app.show_on_sidebar" />
        </div>

        <div v-if="app.show_on_sidebar" class="grid grid-cols-2 gap-4 py-2 border-t border-b border-n-weak my-2">
          <div>
            <label class="text-xs font-medium text-n-slate-11 block mb-1">
              Posição na Sidebar
            </label>
            <select
              v-model="app.sidebar_placement"
              class="w-full text-sm rounded border border-n-weak bg-n-background px-3 py-2 text-n-slate-12"
            >
              <option value="main">Botão Principal de Topo</option>
              <option value="apps">Submenu "Apps"</option>
            </select>
          </div>
          <div>
            <label class="text-xs font-medium text-n-slate-11 block mb-1">
              Ícone
            </label>
            <select
              v-model="app.icon"
              class="w-full text-sm rounded border border-n-weak bg-n-background px-3 py-2 text-n-slate-12"
            >
              <option
                v-for="iconOption in availableIcons"
                :key="iconOption.value"
                :value="iconOption.value"
              >
                {{ iconOption.label }}
              </option>
            </select>
          </div>
        </div>

        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <NextButton
            faded
            slate
            type="reset"
            :label="
              $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.CREATE.FORM_CANCEL')
            "
            @click.prevent="closeModal"
          />
          <NextButton
            type="submit"
            :label="submitButtonLabel"
            :disabled="v$.$invalid"
            :is-loading="isLoading"
          />
        </div>
      </form>
    </div>
  </woot-modal>
</template>
