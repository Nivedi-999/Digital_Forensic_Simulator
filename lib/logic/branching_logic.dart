// lib/logic/branching_logic.dart
//
// DYNAMIC SUSPICION SYSTEM
// ─────────────────────────
// Per the game design brief: culprit suspicion starts LOW and rises
// ONLY as the player collects incriminating evidence.
//
// All suspects now start at 0.05 (barely visible bar).
// The riskLevel field is used only for UI colour — NOT for seeding suspicion.
// Evidence effects are the sole driver of suspicion changes.

import '../models/case.dart';

class BranchingLogic {
  final CaseFile caseFile;
  BranchingLogic(this.caseFile);

  // ── 1. Initial suspicion seeds ───────────────────────────
  //
  // CHANGED: All suspects start equal and low (0.05).
  // riskLevel no longer pre-biases the culprit's bar.
  // The player must collect evidence to raise any suspect's suspicion.

  double initialSuspicion(String riskLevel) => 0.05;

  // ── 2. Evidence effects ──────────────────────────────────
  //
  // Culprit evidence: raises culprit bar significantly (+0.15 to +0.25)
  // Red herring evidence: raises innocent suspect bar briefly (+0.15 to +0.20)
  // Contradicting evidence: lowers innocent suspect bar (-0.10 to -0.15)
  //
  // Design goal:
  //   Easy/Medium  — culprit's bar climbs clearly above others by midgame
  //   Hard         — culprit and 1 innocent rise together until late evidence
  //   Advanced     — multiple suspects rise and fall; culprit only clearly
  //                  identified near the end

  static const Map<String, Map<String, double>> _evidenceEffects = {

    // ── Operation GhostTrace (Easy) ──────────────────────────
    'file_finance':      {'ankita_e': 0.20, 'dhruv_a': 0.05},
    'file_debug':        {'ankita_e': 0.18},
    'file_cache':        {'ankita_e': 0.15},
    'file_credentials':  {'ankita_e': 0.25, 'dhruv_a': -0.15},
    'meta_lastuser':     {'ankita_e': 0.20, 'manav_r': -0.05, 'ayon_k': -0.05},
    'ip_internal':       {'ankita_e': 0.18},
    'ip_external':       {'ankita_e': 0.18, 'dhruv_a': -0.10},
    'file_patch':        {'dhruv_a': 0.15},
    'chat_finance':      {'ankita_e': 0.12},
    'chat_offshore':     {'ankita_e': 0.12},

    // ── Password Heist (Easy) ────────────────────────────────
    'file_gradelog':       {'riya_s': 0.22},
    'file_browserhist':    {'riya_s': 0.22},
    'file_password_note':  {'riya_s': 0.25},
    'chat_dare':           {'riya_s': 0.15},
    'chat_brag':           {'riya_s': 0.15},
    'meta_device':         {'riya_s': 0.20},
    'meta_loginuser':      {'riya_s': 0.20},
    'ip_lab':              {'riya_s': 0.18},
    'chat_brag_classmate': {'classmate_b': 0.18},

    // ── The WiFi Thief (Easy) ────────────────────────────────
    'file_routerlog':    {'neil_v': 0.22},
    'file_maclookup':    {'neil_v': 0.25},
    'file_bandwidth':    {'neil_v': 0.15, 'flat401_resident': -0.10},
    'file_devicename':   {'neil_v': 0.25},
    'meta_signal':       {'neil_v': 0.18},
    'meta_timing':       {'neil_v': 0.15},
    'ip_unknown':        {'neil_v': 0.20},
    'meta_other_device': {'flat401_resident': 0.15},

    // ── Five Star Fraud (Easy) ───────────────────────────────
    'file_accountlog':        {'suresh_k': 0.22},
    'file_devicefingerprint': {'suresh_k': 0.22},
    'file_ipreg':             {'suresh_k': 0.28},
    'meta_review_timing':     {'suresh_k': 0.15},
    'meta_location':          {'suresh_k': 0.18},
    'ip_single':              {'suresh_k': 0.25, 'biryani_hub_owner': -0.15},
    'chat_rival_tip':         {'biryani_hub_owner': 0.18},
    'meta_rival_check':       {'biryani_hub_owner': -0.15},

    // ── Dream Job Scam (Easy) ────────────────────────────────
    'file_domain_reg':    {'ramesh_p': 0.25, 'job_portal_admin': -0.15},
    'file_upi_trace':     {'ramesh_p': 0.25},
    'file_prior_case':    {'ramesh_p': 0.22},
    'chat_offer':         {'ramesh_p': 0.15, 'unknown_student': 0.18},
    'chat_upi_confirm':   {'ramesh_p': 0.15},
    'meta_site_clone':    {'ramesh_p': 0.18},
    'ip_registration':    {'ramesh_p': 0.22},
    'meta_portal_admin':  {'job_portal_admin': 0.18},

    // ── Phantom Transaction (Medium) ─────────────────────────
    // Medium: culprit rises clearly but red herring keeps one innocent elevated
    'file_simclone':         {'vikram_b': 0.20, 'external_fraudster': -0.15},
    'file_banktransfer':     {'vikram_b': 0.18},
    'file_employeelog':      {'vikram_b': 0.22},
    'file_bankaccount':      {'vikram_b': 0.22},
    'chat_otp_received':     {'vikram_b': 0.12},
    'chat_transfer_confirm': {'vikram_b': 0.12},
    'chat_social_eng':       {'vikram_b': 0.08},
    'meta_otpdevice':        {'vikram_b': 0.18},
    'ip_backend':            {'vikram_b': 0.20},
    'chat_social_eng_suspect': {'external_fraudster': 0.18},

    // ── Silent Attendance Hack (Medium) ──────────────────────
    'file_dblog':        {'tanmay_d': 0.20},
    'file_sqlqueries':   {'tanmay_d': 0.22},
    'file_hostelwifi':   {'tanmay_d': 0.25, 'unknown_student': -0.15},
    'meta_credentials':  {'tanmay_d': 0.18},
    'ip_hostel':         {'tanmay_d': 0.22},

    // ── The Impersonator (Medium) ────────────────────────────
    'file_emailheader':   {'arpit_c': 0.20},
    'file_vendoraccount': {'arpit_c': 0.22},
    'file_voiceanalysis': {'arpit_c': 0.20},
    'file_vendorhistory': {'arpit_c': 0.18},
    'meta_domain':        {'arpit_c': 0.22},
    'ip_spoof_origin':    {'arpit_c': 0.20},
    'chat_spoofed_email': {'arpit_c': 0.15},
    'chat_voice_confirm': {'arpit_c': 0.15},
    'chat_real_cfo':      {'arpit_c': 0.08},
    'chat_it_admin':      {'it_admin': 0.18},

    // ── The Last Login (Medium) ──────────────────────────────
    'device_login':       {'unknown_system': 0.25},
    'device_timing':      {'unknown_system': 0.25},
    'ip_simultaneous':    {'unknown_system': 0.22},
    'ip_server':          {'unknown_system': 0.22},
    'chat_deadline':      {'unknown_system': 0.15},
    'chat_joke':          {'unknown_system': 0.10},
    'chat_reply':         {'unknown_system': 0.15},
    'ip_rhea_home':       {'rhea_singh': 0.12},

    // ── Cloud Drain (Medium) ─────────────────────────────────
    'file_cloudtrail':    {'ketan_s': 0.20},
    'file_gitleak':       {'ketan_s': 0.22},
    'file_wallet_trace':  {'ketan_s': 0.22},
    'file_vpn_trace':     {'ketan_s': 0.22, 'ex_intern': -0.15},
    'chat_git_commit':    {'ketan_s': 0.18},
    'chat_mining_config': {'ketan_s': 0.18},
    'meta_instance_count':{'ketan_s': 0.15},
    'ip_api_calls':       {'ketan_s': 0.20},
    'chat_ex_intern':     {'ex_intern': 0.18},

    // ── Dead Drop Signal (Hard) ──────────────────────────────
    // Hard: two suspects rise together — operator and lab manager
    // Lab manager's bar only drops late when remote-session evidence appears
    'file_sim_cache':     {'hidden_operator': 0.18},
    'file_render_test':   {'hidden_operator': 0.18},
    'file_calc_patch':    {'hidden_operator': 0.18},
    'meta_sim_cache':     {'hidden_operator': 0.15},
    'meta_render_test':   {'hidden_operator': 0.15},
    'meta_weekly_cycle':  {'hidden_operator': 0.18},
    'ip_internal_relay':  {'hidden_operator': 0.15},
    'ip_dead_drop':       {'hidden_operator': 0.22},
    // Red herring — lab manager rises until remote-session evidence clears him
    'meta_lab_manager':   {'lab_manager': 0.18},
     // remote deploy clears him

    // ── Echoes of Tomorrow (Hard) ────────────────────────────
    'file_preemptive_archive': {'manav_r': 0.22, 'auto_scheduler': -0.15},
    'file_response_model':     {'manav_r': 0.22},
    'chat_preemptive_reply':   {'manav_r': 0.18},
    'ip_simulated_external':   {'manav_r': 0.18},
    'ip_no_external_exit':     {'manav_r': 0.15},
    'chat_confusion':          {'auto_scheduler': 0.15},
    'chat_normal':             {'manav_r': 0.05},

    // ── Echo Without a Voice (Hard) ──────────────────────────
    'chat_threat_1':          {'maya_kulkarni': 0.12},
    'chat_threat_2':          {'maya_kulkarni': 0.12},
    'chat_threat_3':          {'maya_kulkarni': 0.12},
    'meta_account_lifecycle': {'maya_kulkarni': 0.18},
    'meta_fingerprint':       {'maya_kulkarni': 0.18, 'vikram_sen': -0.10},
    'ip_vpn_rotation':        {'maya_kulkarni': 0.12, 'vikram_sen': 0.12},
    'ip_activity_window':     {'maya_kulkarni': 0.15},
    'file_account_creation':  {'maya_kulkarni': 0.18},
    'file_draft_content':     {'maya_kulkarni': 0.20, 'vikram_sen': -0.12},
    'file_prior_dispute':     {'maya_kulkarni': 0.20},
    'file_style_analysis':    {'maya_kulkarni': 0.25},
    // Vikram rises with VPN evidence then drops with draft content
    'ip_vikram_home':         {'vikram_sen': 0.15},

    // ── Dark Proxy Attack (Hard) ─────────────────────────────
    'file_trafficanalysis':   {'dhruv_n': 0.18, 'nullfront_group': -0.15},
    'file_proxytrace':        {'dhruv_n': 0.18},
    'file_vpspurchase':       {'dhruv_n': 0.22},
    'file_configmatch':       {'dhruv_n': 0.22},
    'chat_threat':            {'dhruv_n': 0.12},
    'chat_nullfront':         {'dhruv_n': 0.08},
    'meta_scriptmatch':       {'dhruv_n': 0.18},
    'ip_entrynode':           {'dhruv_n': 0.18},
    'ip_tor_false':           {'dhruv_n': 0.15},
    'chat_ratelimit':         {'nullfront_group': 0.18},

    // ── Poisoned Patch (Hard) ────────────────────────────────
    'file_git_diff':      {'cyrus_f': 0.22},
    'file_financial':     {'cyrus_f': 0.22},
    'file_firmware_diff': {'cyrus_f': 0.18},
    'file_c2_server':     {'cyrus_f': 0.22},
    'chat_conference':    {'cyrus_f': 0.12},
    'chat_shell_command': {'cyrus_f': 0.18},
    'chat_plant_alarm':   {'cyrus_f': 0.05},
    'meta_build_access':  {'cyrus_f': 0.18},
    'meta_shell_timing':  {'cyrus_f': 0.15},
    'ip_c2':              {'cyrus_f': 0.18},
    'ip_build_machine':   {'cyrus_f': 0.22},
    'meta_qa_flag':       {'vendor_qa': 0.18},

    // ── The Vanishing Vault (Advanced) ───────────────────────
    // Advanced: storage vendor AND ishaan both rise — vault clears vendor late
    'file_wiper_code':      {'ishaan_m': 0.15},
    'file_deployment_log':  {'ishaan_m': 0.20, 'storage_vendor': -0.15},
    'file_salary_trace':    {'ishaan_m': 0.20},
    'file_backdoor':        {'ishaan_m': 0.20},
    'ip_wiper_deploy':      {'ishaan_m': 0.18},
    'chat_contractor':      {'storage_vendor': 0.18},

    // ── Mirror Protocol (Advanced) ───────────────────────────
    'file_diff_analysis':    {'zoya_r': 0.15},
    'file_exfil_traffic':    {'zoya_r': 0.15},
    'file_domain_reg_mirror':{'zoya_r': 0.20},
    'file_commit_signature': {'zoya_r': 0.22, 'oss_maintainer': -0.15},
    'meta_commit_window':    {'zoya_r': 0.18},
    'ip_exfil_dest':         {'zoya_r': 0.18},
    'chat_maintainer':       {'oss_maintainer': 0.18},

    // ── Zero Point Entry (Advanced) ──────────────────────────
    'file_exploit_code':  {'ronak_s': 0.15},
    'file_scada_access':  {'ronak_s': 0.20, 'dr_priya_t': -0.15},
    'file_pgp_key':       {'ronak_s': 0.22},
    'chat_exploit_sale':  {'ronak_s': 0.12},
    'chat_early_kill':    {'ronak_s': 0.12},
    'meta_code_style':    {'ronak_s': 0.18},
    'ip_jumpserver':      {'ronak_s': 0.18},
    'chat_old_memo':      {'dr_priya_t': 0.18},

    // ── Ghost Network (Advanced) ─────────────────────────────
    'file_stego_reports':     {'nalini_v': 0.15},
    'file_lateral_movement':  {'nalini_v': 0.18, 'new_engineer': -0.15},
    'file_financial_trace':   {'nalini_v': 0.18},
    'file_handler_identity':  {'nalini_v': 0.20},
    'meta_access_pattern':    {'nalini_v': 0.18},
    'meta_stego_timing':      {'nalini_v': 0.18},
    'ip_canary_access':       {'nalini_v': 0.18},
    'chat_canary_alert':      {'nalini_v': 0.12},
    'chat_handler':           {'nalini_v': 0.12},
    'chat_recruitment':       {'new_engineer': 0.18},

    // ── Double Agent (Advanced) ──────────────────────────────
    // Advanced: both ananya_v and rahil_d rise — only relay ownership clears rahil
    'file_dual_employment':      {'ananya_v': 0.20},
    'file_exfil_log_payaxis':    {'ananya_v': 0.18},
    'file_exfil_log_clearvault': {'ananya_v': 0.18, 'rahil_d': -0.15},
    'file_relay_ownership':      {'ananya_v': 0.22},
    'chat_buyer':                {'ananya_v': 0.18},
    'chat_same_relay':           {'ananya_v': 0.18},
    'meta_same_home_ip':         {'ananya_v': 0.18},
    'meta_tool_signature':       {'ananya_v': 0.18},
    'meta_timeline_overlap':     {'ananya_v': 0.12},
    'ip_relay':                  {'ananya_v': 0.18},
    'chat_colleague_flag':       {'rahil_d': 0.18},
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
    'decryption':         {'ankita_e': 0.12, 'dhruv_a': -0.15, 'manav_r': -0.05, 'ayon_k': -0.05},
    'name_decode':        {'riya_s': 0.12, 'classmate_b': -0.10},
    'hostname_decode':    {'neil_v': 0.12},
    'restaurant_decode':  {'suresh_k': 0.12, 'biryani_hub_owner': -0.10},
    'sim_decode':         {'vikram_b': 0.12, 'external_fraudster': -0.10},
    'student_decode':     {'tanmay_d': 0.12, 'unknown_student': -0.10},
    'vendor_decode':      {'arpit_c': 0.12, 'it_admin': -0.10},
    'vpn_decode':         {'ketan_s': 0.12, 'ex_intern': -0.10},
    'alias_decode':       {'maya_kulkarni': 0.15, 'vikram_sen': -0.12},
    'dhruv_decode':       {'dhruv_n': 0.12, 'nullfront_group': -0.10},
    'c2_decode':          {'cyrus_f': 0.12, 'vendor_qa': -0.10},
    'ishaan_decode':      {'ishaan_m': 0.12, 'storage_vendor': -0.12},
    'zoya_decode':        {'zoya_r': 0.12, 'oss_maintainer': -0.12},
    'ronak_decode':       {'ronak_s': 0.12, 'dr_priya_t': -0.12},
    'nalini_decode':      {'nalini_v': 0.12, 'new_engineer': -0.12},
    'relay_decode':       {'ananya_v': 0.12, 'rahil_d': -0.12},
    'name_decode_ramesh': {'ramesh_p': 0.12, 'job_portal_admin': -0.10},
    'dead_drop_decode':   {'hidden_operator': 0.15},
    'echoes_decode':      {'manav_r': 0.12, 'auto_scheduler': -0.10},
    'last_login_decode':  {'unknown_system': 0.15, 'rhea_singh': -0.10},
    'hostel_decode':      {'tanmay_d': 0.12, 'unknown_student': -0.10},
    'account_decode':     {'vikram_b': 0.12, 'external_fraudster': -0.10},
    'proxy_decode':       {'dhruv_n': 0.12, 'nullfront_group': -0.10},
    'vault_decode':       {'ishaan_m': 0.12, 'storage_vendor': -0.12},
    'commit_decode':      {'zoya_r': 0.12, 'oss_maintainer': -0.12},
    'pgp_decode':         {'ronak_s': 0.12, 'dr_priya_t': -0.12},
    'handler_decode':     {'nalini_v': 0.12, 'new_engineer': -0.12},
    'ip_decode':          {'suresh_k': 0.12},
    'network_decode':     {'neil_v': 0.12},
    'password_pattern':   {'riya_s': 0.12},
    'binary_pattern':     {'hidden_operator': 0.12},
    'intent_patterning':  {'manav_r': 0.12},
    'linguistic_patterning': {'maya_kulkarni': 0.15},
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
    final spamming = totalAvailableEvidence > 0 &&
        totalEvidenceCount / totalAvailableEvidence >= 0.8;
    if (spamming || isTimeUp) return OutcomeType.partial;
    return OutcomeType.perfect;
  }
}