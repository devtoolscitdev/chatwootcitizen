module SuperAdmin::AccountFeaturesHelper
  def self.account_features
    YAML.safe_load(Rails.root.join('config/features.yml').read).freeze
  end

  def self.account_premium_features
    account_features.filter { |feature| feature['premium'] }.pluck('name')
  end

  FEATURE_PT_BR_NAMES = {
    'account_settings' => 'Conta (Configurações Gerais)',
    'agent_management' => 'Agentes',
    'team_management' => 'Times',
    'assignment_policy' => 'Atribuição de Agentes',
    'inbox_management' => 'Caixas de Entrada',
    'labels' => 'Etiquetas',
    'custom_attributes' => 'Atributos Personalizados',
    'automations' => 'Automação',
    'agent_bots' => 'Robôs (Agent Bots)',
    'macros' => 'Macros',
    'canned_responses' => 'Respostas Prontas',
    'integrations' => 'Integrações',
    'sidebar_customization' => 'Personalização do Menu Lateral',
    'audit_logs' => 'Auditoria (Audit Logs)',
    'custom_roles' => 'Funções Personalizadas (Roles)',
    'sla' => 'SLA (Acordos de Nível de Serviço)',
    'saml' => 'Segurança (SAML SSO)',
    'reports' => 'Relatórios',
    'campaigns' => 'Campanhas',
    'help_center' => 'Central de Ajuda',
    'captain_integration' => 'Capitão (IA Captain)',
    'captain_integration_v2' => 'Capitão V2 (IA Captain)',
    'voice_recorder' => 'Gravador de Voz',
    'disable_branding' => 'Desabilitar Marca Chatwoot',
    'auto_resolve_conversations' => 'Auto-resolver Conversas',
    'companies' => 'Empresas',
    'channel_email' => 'Canal Email',
    'inbound_emails' => 'Recebimento de Emails (Inbound)',
    'quoted_email_reply' => 'Resposta Citada em Email',
    'custom_reply_email' => 'Email Customizado de Resposta',
    'custom_reply_domain' => 'Domínio Customizado de Resposta',
    'channel_facebook' => 'Canal Facebook',
    'channel_instagram' => 'Canal Instagram',
    'channel_tiktok' => 'Canal TikTok',
    'channel_website' => 'Canal Website (Live Chat)',
    'channel_voice' => 'Canal de Voz',
    'whatsapp_campaign' => 'Campanhas WhatsApp',
    'linear_integration' => 'Integração Linear',
    'notion_integration' => 'Integração Notion',
    'ip_lookup' => 'Consulta de IP'
  }.freeze

  def self.feature_display_names
    names = {}
    account_features.each do |feature|
      name = feature['name']
      names[name] = FEATURE_PT_BR_NAMES[name] || feature['display_name'] || name.titleize
    end
    names
  end

  def self.filter_internal_features(features)
    return features if ChatwootApp.chatwoot_cloud?

    internal_features = account_features.select { |f| f['chatwoot_internal'] }.pluck('name')
    features.except(*internal_features)
  end

  def self.filter_deprecated_features(features)
    deprecated_features = account_features.select { |f| f['deprecated'] }.pluck('name')
    features.except(*deprecated_features)
  end

  GROUPS = [
    {
      id: :settings_menu,
      title: "Menu de Configurações (Submenus)",
      description: "Controle individual de visibilidade para cada item da seção Configurações da conta.",
      keys: %w[
        account_settings
        agent_management
        team_management
        assignment_policy
        inbox_management
        labels
        custom_attributes
        automations
        agent_bots
        macros
        canned_responses
        integrations
        sidebar_customization
        audit_logs
        custom_roles
        sla
        saml
      ]
    },
    {
      id: :main_modules,
      title: "Módulos do Painel Principal",
      description: "Módulos e ferramentas da barra lateral e operação do sistema.",
      keys: %w[
        reports
        campaigns
        help_center
        captain_integration
        captain_integration_v2
        voice_recorder
        disable_branding
        auto_resolve_conversations
        companies
      ]
    },
    {
      id: :channels,
      title: "Canais de Comunicação e Integrações",
      description: "Canais de atendimento ao cliente, mensageria e integrações externas.",
      keys: %w[
        channel_email
        inbound_emails
        quoted_email_reply
        custom_reply_email
        custom_reply_domain
        channel_facebook
        channel_instagram
        channel_tiktok
        channel_website
        channel_voice
        whatsapp_campaign
        linear_integration
        notion_integration
        ip_lookup
      ]
    }
  ].freeze

  def self.categorized_features(features)
    cleaned = filter_deprecated_features(features)
    display_names = feature_display_names
    used_keys = []

    result = GROUPS.map do |group|
      group_features = {}
      group[:keys].each do |key|
        if cleaned.key?(key)
          group_features[[key, display_names[key] || key]] = cleaned[key]
          used_keys << key
        end
      end
      group.merge(features: group_features)
    end

    remaining_keys = cleaned.keys - used_keys
    if remaining_keys.any?
      remaining_features = {}
      remaining_keys.sort.each do |key|
        remaining_features[[key, display_names[key] || key]] = cleaned[key]
      end
      result << {
        id: :other,
        title: "Outros Recursos",
        description: "Configurações complementares do sistema.",
        features: remaining_features
      }
    end

    result
  end

  def self.sort_and_transform_features(features, display_names)
    features.sort_by { |key, _| display_names[key] || key }
            .to_h
            .transform_keys { |key| [key, display_names[key]] }
  end

  def self.partition_features(features)
    filtered = filter_internal_features(features)
    filtered = filter_deprecated_features(filtered)
    display_names = feature_display_names

    regular, premium = filtered.partition { |key, _value| account_premium_features.exclude?(key) }

    [
      sort_and_transform_features(regular, display_names),
      sort_and_transform_features(premium, display_names)
    ]
  end

  def self.filtered_features(features)
    regular, premium = partition_features(features)
    regular.merge(premium)
  end
end
