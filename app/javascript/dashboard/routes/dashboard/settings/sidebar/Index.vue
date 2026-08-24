<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'next/switch/Switch.vue';

const { t } = useI18n();
const store = useStore();
const { currentAccount, updateAccount } = useAccount();
const isSaving = ref(false);

const dashboardApps = useMapGetter('dashboardApps/getRecords');

const defaultMenuItems = [
  { id: 'inbox', label: 'Caixa de Entrada (Notificações)', icon: 'i-lucide-inbox', defaultVisible: true },
  { id: 'conversations', label: 'Conversas e Atendimentos', icon: 'i-lucide-message-circle', defaultVisible: true },
  { id: 'contacts', label: 'Contatos & Segmentos', icon: 'i-lucide-contact', defaultVisible: true },
  { id: 'reports', label: 'Relatórios de Atendimento', icon: 'i-lucide-chart-pie', defaultVisible: true },
  { id: 'campaigns', label: 'Campanhas', icon: 'i-lucide-megaphone', defaultVisible: true },
  { id: 'help_center', label: 'Central de Ajuda', icon: 'i-lucide-book-open-text', defaultVisible: true },
  { id: 'captain', label: 'Capitão (Captain AI)', icon: 'i-woot-captain', defaultVisible: false },
];

const menuList = ref([]);

const initMenuList = () => {
  const settings = currentAccount.value?.settings || {};
  const sidebarConfig = settings.sidebar_config || {};
  const hiddenItems = Array.isArray(sidebarConfig.hidden_items) ? sidebarConfig.hidden_items : [];
  const itemOrder = Array.isArray(sidebarConfig.item_order) ? sidebarConfig.item_order : [];

  // Montar lista com itens nativos + apps customizados
  const allItems = [...defaultMenuItems];

  // Adicionar apps customizados cadastrados
  if (dashboardApps.value && dashboardApps.value.length > 0) {
    dashboardApps.value.forEach(app => {
      allItems.push({
        id: `custom_app_${app.id}`,
        label: `${app.title} (App Customizado)`,
        icon: app.icon || 'i-lucide-layout-grid',
        defaultVisible: app.show_on_sidebar ?? true,
      });
    });
  }

  // Mapear estado de visibilidade
  const itemsWithState = allItems.map(item => ({
    ...item,
    visible: !hiddenItems.includes(item.id),
  }));

  // Ordenar conforme itemOrder
  if (itemOrder.length > 0) {
    itemsWithState.sort((a, b) => {
      const indexA = itemOrder.indexOf(a.id);
      const indexB = itemOrder.indexOf(b.id);
      if (indexA === -1 && indexB === -1) return 0;
      if (indexA === -1) return 1;
      if (indexB === -1) return -1;
      return indexA - indexB;
    });
  }

  menuList.value = itemsWithState;
};

onMounted(async () => {
  try {
    if (!dashboardApps.value?.length) {
      await store.dispatch('dashboardApps/get');
    }
  } catch (error) {
    // ignore
  }
  initMenuList();
});

const moveUp = index => {
  if (index <= 0) return;
  const item = menuList.value.splice(index, 1)[0];
  menuList.value.splice(index - 1, 0, item);
};

const moveDown = index => {
  if (index >= menuList.value.length - 1) return;
  const item = menuList.value.splice(index, 1)[0];
  menuList.value.splice(index + 1, 0, item);
};

const resetToDefault = () => {
  initMenuList();
  menuList.value.forEach(item => {
    item.visible = item.defaultVisible;
  });
  useAlert('Padrão restaurado. Clique em Salvar para aplicar.');
};

const saveConfig = async () => {
  try {
    isSaving.value = true;
    const hidden_items = menuList.value
      .filter(item => !item.visible)
      .map(item => item.id);

    const item_order = menuList.value.map(item => item.id);

    const isCaptainHidden = hidden_items.includes('captain');

    await updateAccount({
      hide_captain: isCaptainHidden,
      sidebar_config: {
        hidden_items,
        item_order,
      },
    });

    useAlert('Configuração do Menu Lateral salva com sucesso!');
  } catch (error) {
    useAlert('Erro ao salvar configurações da barra lateral.');
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col w-full max-w-4xl ltr:mr-auto rtl:ml-auto gap-6">
    <BaseSettingsHeader
      title="Personalização do Menu Lateral (Sidebar)"
      description="Gerencie quais itens e sistemas devem aparecer na barra lateral esquerda e defina a ordem de exibição para sua equipe."
    />

    <div class="bg-n-background border border-n-weak rounded-xl p-6 flex flex-col gap-4 shadow-sm">
      <div class="flex items-center justify-between border-b border-n-weak pb-4">
        <div>
          <h3 class="text-sm font-semibold text-n-slate-12">
            Organização e Visibilidade dos Menus
          </h3>
          <p class="text-xs text-n-slate-11">
            Utilize os botões para reordenar a prioridade e os seletores para ocultar módulos desnecessários.
          </p>
        </div>
        <div class="flex items-center gap-2">
          <NextButton
            faded
            slate
            size="sm"
            label="Restaurar Padrão"
            @click="resetToDefault"
          />
          <NextButton
            blue
            size="sm"
            :is-loading="isSaving"
            label="Salvar Alterações"
            @click="saveConfig"
          />
        </div>
      </div>

      <!-- Lista de Itens do Menu -->
      <div class="flex flex-col divide-y divide-n-weak">
        <div
          v-for="(item, index) in menuList"
          :key="item.id"
          class="flex items-center justify-between py-3 px-2 hover:bg-n-solid-1 rounded-lg transition-colors"
        >
          <div class="flex items-center gap-3">
            <span class="text-xs font-mono text-n-slate-10 w-5 text-center">
              {{ index + 1 }}º
            </span>
            <div class="flex items-center gap-2">
              <span class="text-base text-n-brand" :class="item.icon" />
              <span class="text-sm font-medium text-n-slate-12">
                {{ item.label }}
              </span>
            </div>
          </div>

          <div class="flex items-center gap-4">
            <!-- Botões de Reordenação -->
            <div class="flex items-center gap-1">
              <button
                type="button"
                :disabled="index === 0"
                class="p-1 rounded hover:bg-n-slate-3 text-n-slate-11 disabled:opacity-30 disabled:cursor-not-allowed cursor-pointer"
                title="Mover para cima"
                @click="moveUp(index)"
              >
                ▲
              </button>
              <button
                type="button"
                :disabled="index === menuList.length - 1"
                class="p-1 rounded hover:bg-n-slate-3 text-n-slate-11 disabled:opacity-30 disabled:cursor-not-allowed cursor-pointer"
                title="Mover para baixo"
                @click="moveDown(index)"
              >
                ▼
              </button>
            </div>

            <!-- Switch de Visibilidade -->
            <div class="flex items-center gap-2">
              <span class="text-xs text-n-slate-10">
                {{ item.visible ? 'Visível' : 'Oculto' }}
              </span>
              <Switch v-model="item.visible" />
            </div>
          </div>
        </div>
      </div>

      <div class="flex justify-end pt-4 border-t border-n-weak">
        <NextButton
          blue
          :is-loading="isSaving"
          label="Salvar Alterações"
          @click="saveConfig"
        />
      </div>
    </div>
  </div>
</template>
