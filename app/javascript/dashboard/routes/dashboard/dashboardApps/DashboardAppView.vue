<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  appId: {
    type: [Number, String],
    default: null,
  },
});

const route = useRoute();
const store = useStore();
const { t } = useI18n();
const dashboardApps = useMapGetter('dashboardApps/getRecords');
const currentUser = useMapGetter('getCurrentUser');
const isLoadingApps = ref(true);
const isIframeLoading = ref(true);
const iframeKey = ref(0);

const resolvedAppId = computed(() => {
  const val = props.appId || route.params.appId;
  return Number(val);
});

const dashboardApp = computed(() => {
  return dashboardApps.value.find(app => Number(app.id) === resolvedAppId.value);
});

const appUrl = computed(() => {
  if (!dashboardApp.value?.content) return '';
  const content = dashboardApp.value.content;
  if (Array.isArray(content) && content.length > 0) {
    return content[0].url || '';
  }
  if (typeof content === 'object' && content.url) {
    return content.url;
  }
  return '';
});

const notFound = computed(() => !isLoadingApps.value && !dashboardApp.value);

const reloadIframe = () => {
  isIframeLoading.value = true;
  iframeKey.value += 1;
};

const onIframeLoad = event => {
  isIframeLoading.value = false;
  try {
    const frame = event.target;
    if (frame && frame.contentWindow) {
      const eventData = {
        event: 'appContext',
        data: {
          currentAgent: currentUser.value
            ? {
                id: currentUser.value.id,
                name: currentUser.value.name,
                email: currentUser.value.email,
              }
            : null,
        },
      };
      frame.contentWindow.postMessage(JSON.stringify(eventData), '*');
    }
  } catch (e) {
    // ignore cross-origin error
  }
};

const fetchApps = async () => {
  try {
    isLoadingApps.value = true;
    await store.dispatch('dashboardApps/get');
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to fetch dashboard apps', error);
  } finally {
    isLoadingApps.value = false;
  }
};

onMounted(async () => {
  if (!dashboardApps.value.length) {
    await fetchApps();
  } else {
    isLoadingApps.value = false;
  }
});

watch(resolvedAppId, () => {
  isIframeLoading.value = true;
  iframeKey.value += 1;
});
</script>

<template>
  <div class="flex flex-col w-full h-full bg-n-background font-inter overflow-hidden">
    <div
      v-if="isLoadingApps"
      class="flex items-center justify-center w-full h-full"
    >
      <Spinner />
    </div>
    <div
      v-else-if="notFound"
      class="flex flex-col items-center justify-center w-full h-full px-4 text-center gap-3"
    >
      <span class="i-lucide-layout-grid text-4xl text-n-slate-9" />
      <p class="text-base font-medium text-n-slate-12">
        {{ t('INTEGRATION_SETTINGS.DASHBOARD_APPS.VIEW.NOT_FOUND') || 'Aplicativo não encontrado' }}
      </p>
      <p class="text-xs text-n-slate-10 max-w-sm">
        O aplicativo solicitado não existe ou foi removido desta conta.
      </p>
    </div>
    <div v-else class="flex flex-col w-full h-full min-h-0 overflow-hidden">
      <!-- Header do App -->
      <div
        class="flex items-center justify-between px-6 py-3 border-b border-n-weak bg-n-background shrink-0"
      >
        <div class="flex items-center gap-3">
          <span class="text-xl text-n-brand" :class="dashboardApp.icon || 'i-lucide-layout-grid'" />
          <h1 class="text-base font-semibold text-n-slate-12">
            {{ dashboardApp.title }}
          </h1>
        </div>
        <div class="flex items-center gap-2">
          <button
            type="button"
            class="p-1.5 rounded-lg text-n-slate-11 hover:text-n-slate-12 hover:bg-n-solid-2 text-xs flex items-center gap-1 cursor-pointer transition-colors"
            title="Recarregar aplicativo"
            @click="reloadIframe"
          >
            <span class="i-lucide-rotate-cw size-3.5" :class="{ 'animate-spin': isIframeLoading }" />
            <span class="hidden sm:inline">Recarregar</span>
          </button>
          <a
            v-if="appUrl"
            :href="appUrl"
            target="_blank"
            rel="noopener noreferrer"
            class="p-1.5 rounded-lg text-n-slate-11 hover:text-n-brand hover:bg-n-solid-2 text-xs flex items-center gap-1 cursor-pointer transition-colors"
            title="Abrir em uma nova aba"
          >
            <span class="i-lucide-external-link size-3.5" />
            <span class="hidden sm:inline">Abrir externamente</span>
          </a>
        </div>
      </div>

      <!-- Container do Iframe Embebido -->
      <div class="flex-1 w-full h-full min-h-0 relative overflow-hidden bg-white">
        <div
          v-if="isIframeLoading"
          class="absolute inset-0 z-10 flex flex-col items-center justify-center bg-white/80 backdrop-blur-xs gap-2"
        >
          <Spinner />
          <span class="text-xs text-n-slate-10 font-medium">Carregando aplicativo...</span>
        </div>
        <iframe
          v-if="appUrl"
          :key="iframeKey"
          :src="appUrl"
          class="w-full h-full border-0 block"
          allow="camera; microphone; geolocation; clipboard-read; clipboard-write; fullscreen; payment"
          @load="onIframeLoad"
        />
        <div
          v-else
          class="flex items-center justify-center w-full h-full text-sm text-n-slate-10"
        >
          Nenhuma URL configurada para este aplicativo.
        </div>
      </div>
    </div>
  </div>
</template>
