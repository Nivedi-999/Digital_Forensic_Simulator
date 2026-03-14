// lib/logic/branching_logic.dart

import '../models/case.dart';

class BranchingLogic {
  final CaseFile caseFile;
  BranchingLogic(this.caseFile);

  // ── 1. Initial suspicion seeds ───────────────────────────

  double initialSuspicion(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':   return 0.35;
      case 'medium': return 0.20;
      default:       return 0.10;
    }
  }

  // ── 2. Evidence effects ──────────────────────────────────
  //
  // Format: 'evidence_id': { 'suspect_id': delta }
  // Positive = more suspicious. Negative = less suspicious.
  // Clamped to [0.0, 1.0] after application.
  //
  // IMPORTANT: Dart const maps cannot have duplicate keys.
  // Each evidence_id must appear exactly once.
  // To affect multiple suspects with one item, list all in the same inner map.

  static const Map<String, Map<String, double>> _evidenceEffects = {

    // ── Operation GhostTrace ─────────────────────────────────
    'file_finance':      {'ankita_e': 0.20, 'dhruv_a': 0.05},
    'file_debug':        {'ankita_e': 0.15},
    'file_cache':        {'ankita_e': 0.10},
    'file_credentials':  {'ankita_e': 0.25, 'dhruv_a': -0.15},
    'meta_lastuser':     {'ankita_e': 0.20, 'manav_r': -0.05, 'ayon_k': -0.05},
    'ip_internal':       {'ankita_e': 0.15},
    'ip_external':       {'ankita_e': 0.15, 'dhruv_a': -0.10},
    'file_patch':        {'dhruv_a': 0.15},         // red herring
    'chat_finance':      {'ankita_e': 0.10},
    'chat_offshore':     {'ankita_e': 0.10},

    // ── Password Heist ───────────────────────────────────────
    'file_gradelog':        {'riya_s': 0.20},
    'file_browserhist':     {'riya_s': 0.20},
    'file_password_note':   {'riya_s': 0.25},
    'chat_dare':            {'riya_s': 0.15},
    'chat_brag':            {'riya_s': 0.15},
    'meta_device':          {'riya_s': 0.20},
    'meta_loginuser':       {'riya_s': 0.20},
    'ip_lab':               {'riya_s': 0.15},
    // Red herring: classmate brag — contradicted by browserhist
    'chat_brag_classmate':  {'classmate_b': 0.20},

    // ── The WiFi Thief ───────────────────────────────────────
    'file_routerlog':    {'neil_v': 0.20},
    'file_maclookup':    {'neil_v': 0.25},
    // file_bandwidth also contradicts the red herring
    'file_bandwidth':    {'neil_v': 0.15, 'flat401_resident': -0.10},
    'file_devicename':   {'neil_v': 0.25},
    'meta_signal':       {'neil_v': 0.15},
    'meta_timing':       {'neil_v': 0.15},
    'ip_unknown':        {'neil_v': 0.20},
    // Red herring: second device from Flat 401
    'meta_other_device': {'flat401_resident': 0.15},

    // ── Five Star Fraud ──────────────────────────────────────
    'file_accountlog':        {'suresh_k': 0.20},
    'file_devicefingerprint': {'suresh_k': 0.20},
    'file_ipreg':             {'suresh_k': 0.30},
    // meta_timing exists in multiple cases — use case-specific IDs
    'meta_review_timing':     {'suresh_k': 0.15},
    'meta_location':          {'suresh_k': 0.15},
    // ip_single also contradicts the red herring
    'ip_single':              {'suresh_k': 0.25, 'biryani_hub_owner': -0.15},
    // Red herring: rival restaurant tip
    'chat_rival_tip':         {'biryani_hub_owner': 0.20},
    // meta_rival_check shows BiryaniHub is clean
    'meta_rival_check':       {'biryani_hub_owner': -0.15},

    // ── Dream Job Scam ───────────────────────────────────────
    'file_domain_reg':    {'ramesh_p': 0.25, 'job_portal_admin': -0.15},
    'file_upi_trace':     {'ramesh_p': 0.25},
    'file_prior_case':    {'ramesh_p': 0.20},
    'chat_offer':         {'ramesh_p': 0.15, 'unknown_student': 0.20},
    'chat_upi_confirm':   {'ramesh_p': 0.15},
    'meta_site_clone':    {'ramesh_p': 0.15},
    'ip_registration':    {'ramesh_p': 0.20},
    // Red herring: portal admin approved the listing
    'meta_portal_admin':  {'job_portal_admin': 0.20},

    // ── Phantom Transaction ──────────────────────────────────
    'file_simclone':         {'vikram_b': 0.25, 'external_fraudster': -0.15},
    'file_banktransfer':     {'vikram_b': 0.20},
    'file_employeelog':      {'vikram_b': 0.25},
    'file_bankaccount':      {'vikram_b': 0.25},
    'chat_otp_received':     {'vikram_b': 0.15},
    'chat_transfer_confirm': {'vikram_b': 0.15},
    'chat_social_eng':       {'vikram_b': 0.10},
    'meta_otpdevice':        {'vikram_b': 0.20},
    'ip_backend':            {'vikram_b': 0.20},
    // Red herring: vishing theory
    'chat_social_eng_suspect': {'external_fraudster': 0.20},

    // ── Silent Attendance Hack ───────────────────────────────
    'file_dblog':        {'tanmay_d': 0.20},
    'file_sqlqueries':   {'tanmay_d': 0.20},
    'file_hostelwifi':   {'tanmay_d': 0.25, 'unknown_student': -0.15},
    'meta_credentials':  {'tanmay_d': 0.15},
    'ip_hostel':         {'tanmay_d': 0.20},
    // Red herring: anonymous forum post (chat_offer is shared — handled above in Dream Job)
    // This case uses the same key 'chat_offer' in a different case JSON
    // Since effects are looked up by evidence ID across ALL cases, we use unique IDs per case

    // ── The Impersonator ─────────────────────────────────────
    'file_emailheader':   {'arpit_c': 0.20},
    'file_vendoraccount': {'arpit_c': 0.25},
    'file_voiceanalysis': {'arpit_c': 0.20},
    'file_vendorhistory': {'arpit_c': 0.20},
    'meta_domain':        {'arpit_c': 0.25},
    'ip_spoof_origin':    {'arpit_c': 0.20},
    'chat_spoofed_email': {'arpit_c': 0.15},
    'chat_voice_confirm': {'arpit_c': 0.15},
    'chat_real_cfo':      {'arpit_c': 0.10},
    // Red herring: IT admin theory
    'chat_it_admin':      {'it_admin': 0.20},

    // ── The Last Login ───────────────────────────────────────
    'device_login':       {'unknown_system': 0.25},
    'device_timing':      {'unknown_system': 0.25},
    'ip_simultaneous':    {'unknown_system': 0.20},
    'ip_server':          {'unknown_system': 0.20},
    'chat_deadline':      {'unknown_system': 0.15},
    'chat_joke':          {'unknown_system': 0.10},
    'chat_reply':         {'unknown_system': 0.15},
    // Red herring: Rhea's home IP (shows she wasn't involved)
    'ip_rhea_home':       {'rhea_singh': 0.15},

    // ── Cloud Drain ──────────────────────────────────────────
    'file_cloudtrail':    {'ketan_s': 0.20},
    'file_gitleak':       {'ketan_s': 0.25},
    'file_wallet_trace':  {'ketan_s': 0.25},
    'file_vpn_trace':     {'ketan_s': 0.25, 'ex_intern': -0.15},
    'chat_git_commit':    {'ketan_s': 0.20},
    'chat_mining_config': {'ketan_s': 0.20},
    'meta_instance_count':{'ketan_s': 0.15},
    'ip_api_calls':       {'ketan_s': 0.20},
    // Red herring: ex-intern flagged
    'chat_ex_intern':     {'ex_intern': 0.20},

    // ── Dead Drop Signal ─────────────────────────────────────
    'file_sim_cache':     {'hidden_operator': 0.20},
    'file_render_test':   {'hidden_operator': 0.20},
    'file_calc_patch':    {'hidden_operator': 0.20},
    'meta_sim_cache':     {'hidden_operator': 0.15},
    'meta_render_test':   {'hidden_operator': 0.15},
    'meta_weekly_cycle':  {'hidden_operator': 0.20},
    'ip_internal_relay':  {'hidden_operator': 0.15},
    'ip_dead_drop':       {'hidden_operator': 0.25},
    // Red herring: lab manager had badge access
    'meta_lab_manager':   {'lab_manager': 0.20},

    // ── Echoes of Tomorrow ───────────────────────────────────
    'file_preemptive_archive': {'manav_r': 0.25, 'auto_scheduler': -0.15},
    'file_response_model':     {'manav_r': 0.25},
    'chat_preemptive_reply':   {'manav_r': 0.20},
    'ip_simulated_external':   {'manav_r': 0.20},
    'ip_no_external_exit':     {'manav_r': 0.15},
    // Red herring: automated scheduler theory
    'chat_confusion':          {'auto_scheduler': 0.15},
    'chat_normal':             {'manav_r': 0.05},

    // ── Echo Without a Voice ─────────────────────────────────
    'chat_threat_1':          {'maya_kulkarni': 0.15},
    'chat_threat_2':          {'maya_kulkarni': 0.15},
    'chat_threat_3':          {'maya_kulkarni': 0.15},
    'meta_account_lifecycle': {'maya_kulkarni': 0.20},
    'meta_fingerprint':       {'maya_kulkarni': 0.20, 'vikram_sen': -0.10},
    'ip_vpn_rotation':        {'maya_kulkarni': 0.15, 'vikram_sen': 0.10},
    'ip_activity_window':     {'maya_kulkarni': 0.15},
    'file_account_creation':  {'maya_kulkarni': 0.20},
    'file_draft_content':     {'maya_kulkarni': 0.20, 'vikram_sen': -0.10},
    'file_prior_dispute':     {'maya_kulkarni': 0.20},
    'file_style_analysis':    {'maya_kulkarni': 0.25},
    // Red herring: Vikram's home IP was active
    'ip_vikram_home':         {'vikram_sen': 0.15},

    // ── Dark Proxy Attack ────────────────────────────────────
    'file_trafficanalysis':   {'dhruv_n': 0.20, 'nullfront_group': -0.15},
    'file_proxytrace':        {'dhruv_n': 0.20},
    'file_vpspurchase':       {'dhruv_n': 0.25},
    'file_configmatch':       {'dhruv_n': 0.25},
    'chat_threat':            {'dhruv_n': 0.15},
    'chat_nullfront':         {'dhruv_n': 0.10},
    'meta_scriptmatch':       {'dhruv_n': 0.20},
    'ip_entrynode':           {'dhruv_n': 0.20},
    'ip_tor_false':           {'dhruv_n': 0.15},
    // Red herring: DDoS extortion email from NullFront
    'chat_ratelimit':         {'nullfront_group': 0.20},

    // ── Poisoned Patch ───────────────────────────────────────
    'file_git_diff':      {'cyrus_f': 0.25},
    'file_financial':     {'cyrus_f': 0.25},
    'file_firmware_diff': {'cyrus_f': 0.20},
    'file_c2_server':     {'cyrus_f': 0.25},
    'chat_conference':    {'cyrus_f': 0.15},
    'chat_shell_command': {'cyrus_f': 0.20},
    'chat_plant_alarm':   {'cyrus_f': 0.05},
    'meta_build_access':  {'cyrus_f': 0.20},
    'meta_shell_timing':  {'cyrus_f': 0.15},
    'ip_c2':              {'cyrus_f': 0.20},
    'ip_build_machine':   {'cyrus_f': 0.25},
    // Red herring: QA engineer approved the build
    'meta_qa_flag':       {'vendor_qa': 0.20},

    // ── The Vanishing Vault ──────────────────────────────────
    'file_wiper_code':      {'ishaan_m': 0.20},
    'file_deployment_log':  {'ishaan_m': 0.25, 'storage_vendor': -0.15},
    'file_salary_trace':    {'ishaan_m': 0.25},
    'file_backdoor':        {'ishaan_m': 0.25},
    'ip_wiper_deploy':      {'ishaan_m': 0.20},
    // Red herring: storage vendor had physical access
    'chat_contractor':      {'storage_vendor': 0.20},

    // ── Mirror Protocol ──────────────────────────────────────
    'file_diff_analysis':    {'zoya_r': 0.20},
    'file_exfil_traffic':    {'zoya_r': 0.20},
    'file_domain_reg_mirror':{'zoya_r': 0.25},  // unique ID to avoid clash with dream job scam
    'file_commit_signature': {'zoya_r': 0.25, 'oss_maintainer': -0.15},
    'meta_commit_window':    {'zoya_r': 0.20},
    'ip_exfil_dest':         {'zoya_r': 0.20},
    // Red herring: open source maintainer approved the PR
    'chat_maintainer':       {'oss_maintainer': 0.20},

    // ── Zero Point Entry ─────────────────────────────────────
    'file_exploit_code':  {'ronak_s': 0.20},
    'file_scada_access':  {'ronak_s': 0.25, 'dr_priya_t': -0.15},
    'file_pgp_key':       {'ronak_s': 0.25},
    'chat_exploit_sale':  {'ronak_s': 0.15},
    'chat_early_kill':    {'ronak_s': 0.15},
    'meta_code_style':    {'ronak_s': 0.20},
    'ip_jumpserver':      {'ronak_s': 0.20},
    // Red herring: Dr. Priya flagged for SCADA knowledge
    'chat_old_memo':      {'dr_priya_t': 0.20},

    // ── Ghost Network ────────────────────────────────────────
    'file_stego_reports':     {'nalini_v': 0.20},
    'file_lateral_movement':  {'nalini_v': 0.20, 'new_engineer': -0.15},
    'file_financial_trace':   {'nalini_v': 0.20},
    'file_handler_identity':  {'nalini_v': 0.20},
    'meta_access_pattern':    {'nalini_v': 0.20},
    'meta_stego_timing':      {'nalini_v': 0.20},
    'ip_canary_access':       {'nalini_v': 0.20},
    'chat_canary_alert':      {'nalini_v': 0.15},
    'chat_handler':           {'nalini_v': 0.15},
    // Red herring: new engineer's early access requests
    'chat_recruitment':       {'new_engineer': 0.20},

    // ── Double Agent ─────────────────────────────────────────
    'file_dual_employment':      {'ananya_v': 0.25},
    'file_exfil_log_payaxis':    {'ananya_v': 0.20},
    'file_exfil_log_clearvault': {'ananya_v': 0.20, 'rahil_d': -0.15},
    'file_relay_ownership':      {'ananya_v': 0.25},
    'chat_buyer':                {'ananya_v': 0.20},
    'chat_same_relay':           {'ananya_v': 0.20},
    'meta_same_home_ip':         {'ananya_v': 0.20},
    'meta_tool_signature':       {'ananya_v': 0.20},
    'meta_timeline_overlap':     {'ananya_v': 0.15},
    'ip_relay':                  {'ananya_v': 0.20},
    // Red herring: Rahil asked about checkpoint paths
    'chat_colleague_flag':       {'rahil_d': 0.20},
  };

  void applyEvidenceEffects(String evidenceId, Map<String, double> suspicion) {
    final effects = _evidenceEffects[evidenceId];
    if (effects == null) return;
    for (final entry in effects.entries) {
      final current = suspicion[entry.key] ?? 0.0;
      suspicion[entry.key] = (current + entry.value).clamp(0.0, 1.0);
    }
  }

  // ── 3. Mini-game effects ─────────────────────────────────

  static const Map<String, Map<String, double>> _minigameEffects = {
    // GhostTrace
    'decryption':     {'ankita_e': 0.10, 'dhruv_a': -0.15, 'manav_r': -0.05, 'ayon_k': -0.05},
    // Password Heist
    'name_decode':    {'riya_s': 0.10, 'classmate_b': -0.10},
    // WiFi Thief
    'hostname_decode':{'neil_v': 0.10},
    // Five Star Fraud
    'restaurant_decode': {'suresh_k': 0.10, 'biryani_hub_owner': -0.10},
    // Phantom Transaction
    'sim_decode':     {'vikram_b': 0.10, 'external_fraudster': -0.10},
    // Attendance Hack
    'student_decode': {'tanmay_d': 0.10, 'unknown_student': -0.10},
    // Impersonator
    'vendor_decode':  {'arpit_c': 0.10, 'it_admin': -0.10},
    // Cloud Drain
    'vpn_decode':     {'ketan_s': 0.10, 'ex_intern': -0.10},
    // Echo Without a Voice
    'alias_decode':   {'maya_kulkarni': 0.15, 'vikram_sen': -0.10},
    // Dark Proxy Attack
    'dhruv_decode':   {'dhruv_n': 0.10, 'nullfront_group': -0.10},
    // Poisoned Patch
    'c2_decode':      {'cyrus_f': 0.10, 'vendor_qa': -0.10},
    // Vanishing Vault
    'ishaan_decode':  {'ishaan_m': 0.10, 'storage_vendor': -0.10},
    // Mirror Protocol
    'zoya_decode':    {'zoya_r': 0.10, 'oss_maintainer': -0.10},
    // Zero Point Entry
    'ronak_decode':   {'ronak_s': 0.10, 'dr_priya_t': -0.10},
    // Ghost Network
    'nalini_decode':  {'nalini_v': 0.10, 'new_engineer': -0.10},
    // Double Agent
    'relay_decode':   {'ananya_v': 0.10, 'rahil_d': -0.10},
    // Dream Job Scam
    'name_decode_ramesh': {'ramesh_p': 0.10, 'job_portal_admin': -0.10},
    // Dead Drop Signal
    'dead_drop_decode':   {'hidden_operator': 0.15},
    // Echoes of Tomorrow
    'echoes_decode':      {'manav_r': 0.10, 'auto_scheduler': -0.10},
    // Last Login
    'last_login_decode':  {'unknown_system': 0.15, 'rhea_singh': -0.10},
  };

  void applyMinigameEffects(String minigameId, Map<String, double> suspicion) {
    final effects = _minigameEffects[minigameId];
    if (effects == null) return;
    for (final entry in effects.entries) {
      final current = suspicion[entry.key] ?? 0.0;
      suspicion[entry.key] = (current + entry.value).clamp(0.0, 1.0);
    }
  }

  // ── 4. Outcome resolution ────────────────────────────────

  OutcomeType resolveOutcome({
    required String accusedSuspectId,
    required int correctEvidenceCount,
    required int irrelevantEvidenceCount,
    required int totalEvidenceCount,
    required int totalAvailableEvidence,
    required WinCondition winCondition,
    bool isTimeUp = false,
  }) {
    final isCorrect = accusedSuspectId == winCondition.guiltySuspectId;

    if (!isCorrect) return OutcomeType.wrongAccusation;
    if (correctEvidenceCount == 0) return OutcomeType.coldCase;
    if (correctEvidenceCount < winCondition.minCorrectEvidence) {
      return OutcomeType.partial;
    }

    // Spam-collect: flagged ≥80% of all available evidence
    final spamming = totalAvailableEvidence > 0 &&
        totalEvidenceCount / totalAvailableEvidence >= 0.8;

    if (spamming || isTimeUp) return OutcomeType.partial;

    return OutcomeType.perfect;
  }
}