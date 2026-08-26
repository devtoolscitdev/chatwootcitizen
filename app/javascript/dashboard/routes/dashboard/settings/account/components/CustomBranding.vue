<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import SectionLayout from './SectionLayout.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const { t } = useI18n();
const store = useStore();
const { currentAccount, accountId } = useAccount();

const MAXIMUM_FILE_UPLOAD_SIZE = 5; // in MB
const ALLOWED_TYPES = [
  'image/png',
  'image/jpeg',
  'image/svg+xml',
  'image/webp',
];

const logoUrl = ref('');
const logoDarkUrl = ref('');
const logoThumbnailUrl = ref('');
const isUploading = ref({
  logo: false,
  logo_dark: false,
  logo_thumbnail: false,
});

watch(
  currentAccount,
  () => {
    const logos = currentAccount.value?.custom_logos || {};
    logoUrl.value = logos.logo || '';
    logoDarkUrl.value = logos.logo_dark || '';
    logoThumbnailUrl.value = logos.logo_thumbnail || '';
  },
  { deep: true, immediate: true }
);

const logoFields = computed(() => [
  {
    key: 'logo',
    label: t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.LOGO.LABEL'),
    help: t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.LOGO.HELP'),
    url: logoUrl.value,
    icon: 'i-lucide-sun',
  },
  {
    key: 'logo_dark',
    label: t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.LOGO_DARK.LABEL'),
    help: t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.LOGO_DARK.HELP'),
    url: logoDarkUrl.value,
    icon: 'i-lucide-moon',
  },
  {
    key: 'logo_thumbnail',
    label: t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.LOGO_THUMBNAIL.LABEL'),
    help: t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.LOGO_THUMBNAIL.HELP'),
    url: logoThumbnailUrl.value,
    icon: 'i-lucide-image',
  },
]);

function validateFile(file) {
  if (!checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
    useAlert(t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.API.SIZE_ERROR'));
    return false;
  }
  if (!ALLOWED_TYPES.includes(file.type)) {
    useAlert(t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.API.FORMAT_ERROR'));
    return false;
  }
  return true;
}

async function handleUpload(logoType, event) {
  const file = event.target.files[0];
  if (!file) return;
  if (!validateFile(file)) return;

  isUploading.value[logoType] = true;
  try {
    const { blobId } = await uploadFile(file, accountId.value);
    await store.dispatch('accounts/updateLogo', {
      logoType,
      blobId,
    });
    useAlert(t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.API.ERROR'));
  } finally {
    isUploading.value[logoType] = false;
    // Reset input value so same file can be re-uploaded
    event.target.value = '';
  }
}

async function handleDelete(logoType) {
  if (!confirm(t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.REMOVE_CONFIRM'))) {
    return;
  }
  try {
    await store.dispatch('accounts/deleteLogo', { logoType });
    useAlert(t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.API.DELETE_SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.API.DELETE_ERROR'));
  }
}

function triggerUpload(logoType) {
  const input = document.getElementById(`logo-upload-${logoType}`);
  if (input) input.click();
}
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.NOTE')"
    with-border
  >
    <div class="grid gap-6">
      <div
        v-for="field in logoFields"
        :key="field.key"
        class="flex flex-col gap-3 p-4 rounded-xl border border-n-weak bg-n-alpha-1"
      >
        <!-- Header with label and icon -->
        <div class="flex items-center gap-2">
          <Icon :icon="field.icon" class="size-4 text-n-slate-11" />
          <h5 class="text-sm font-medium text-n-slate-12">
            {{ field.label }}
          </h5>
        </div>

        <!-- Help text with dimensions and format info -->
        <p class="text-xs text-n-slate-11 leading-relaxed">
          {{ field.help }}
        </p>

        <!-- Preview and actions -->
        <div class="flex items-center gap-4">
          <!-- Logo preview -->
          <div
            class="flex items-center justify-center w-40 h-16 rounded-lg border border-dashed border-n-weak bg-n-background overflow-hidden"
          >
            <img
              v-if="field.url"
              :src="field.url"
              :alt="field.label"
              class="max-w-full max-h-full object-contain p-2"
            />
            <span
              v-else
              class="text-xs text-n-slate-10 text-center px-2"
            >
              {{ t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.NO_LOGO') }}
            </span>
          </div>

          <!-- Action buttons -->
          <div class="flex gap-2">
            <input
              :id="`logo-upload-${field.key}`"
              type="file"
              accept=".png,.jpg,.jpeg,.svg,.webp"
              class="hidden"
              @change="handleUpload(field.key, $event)"
            />
            <NextButton
              sm
              faded
              blue
              :is-loading="isUploading[field.key]"
              :label="t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.UPLOAD')"
              icon="i-lucide-upload"
              @click="triggerUpload(field.key)"
            />
            <NextButton
              v-if="field.url"
              sm
              faded
              ruby
              :label="t('GENERAL_SETTINGS.FORM.CUSTOM_BRANDING.REMOVE')"
              icon="i-lucide-trash-2"
              @click="handleDelete(field.key)"
            />
          </div>
        </div>
      </div>
    </div>
  </SectionLayout>
</template>
