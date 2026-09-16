/*jslint
        browser
*/
/*global
        Event, nslog, window
*/
//  Copyright 2016-2017 Paul Theriault and David Park. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
// adapted from chrome app polyfill https://github.com/WebBluetoothCG/chrome-app-polyfill

(function () {
  'use strict';
  nslog('Create BluetoothUUID');

  function canonicalUUID(uuidAlias) {
    // https://www.bluetooth.com/specifications/assigned-numbers/service-discovery
    uuidAlias >>>= 0;  // Make sure the number is positive and 32 bits.
    let strAlias = `0000000${uuidAlias.toString(16)}`;
    strAlias = strAlias.substr(-8);
    return strAlias + '-0000-1000-8000-00805f9b34fb';
  }

  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  const shortUUIDRegex = /^[0-9a-f]{4}([0-9a-f]{4})?$/i;

  let BluetoothUUID = {};
  BluetoothUUID.canonicalUUID = canonicalUUID;
  BluetoothUUID.service = {
    alert_notification: canonicalUUID(0x1811),
    automation_io: canonicalUUID(0x1815),
    battery_service: canonicalUUID(0x180F),
    blood_pressure: canonicalUUID(0x1810),
    body_composition: canonicalUUID(0x181B),
    bond_management: canonicalUUID(0x181E),
    continuous_glucose_monitoring: canonicalUUID(0x181F),
    current_time: canonicalUUID(0x1805),
    cycling_power: canonicalUUID(0x1818),
    cycling_speed_and_cadence: canonicalUUID(0x1816),
    device_information: canonicalUUID(0x180A),
    environmental_sensing: canonicalUUID(0x181A),
    generic_access: canonicalUUID(0x1800),
    generic_attribute: canonicalUUID(0x1801),
    glucose: canonicalUUID(0x1808),
    health_thermometer: canonicalUUID(0x1809),
    heart_rate: canonicalUUID(0x180D),
    human_interface_device: canonicalUUID(0x1812),
    immediate_alert: canonicalUUID(0x1802),
    indoor_positioning: canonicalUUID(0x1821),
    internet_protocol_support: canonicalUUID(0x1820),
    link_loss: canonicalUUID(0x1803),
    location_and_navigation: canonicalUUID(0x1819),
    next_dst_change: canonicalUUID(0x1807),
    phone_alert_status: canonicalUUID(0x180E),
    pulse_oximeter: canonicalUUID(0x1822),
    reference_time_update: canonicalUUID(0x1806),
    running_speed_and_cadence: canonicalUUID(0x1814),
    scan_parameters: canonicalUUID(0x1813),
    tx_power: canonicalUUID(0x1804),
    user_data: canonicalUUID(0x181C),
    weight_scale: canonicalUUID(0x181D)
  };

  BluetoothUUID.characteristic = {
    aerobic_heart_rate_lower_limit: canonicalUUID(0x2A7E),
    aerobic_heart_rate_upper_limit: canonicalUUID(0x2A84),
    aerobic_threshold: canonicalUUID(0x2A7F),
    age: canonicalUUID(0x2A80),
    aggregate: canonicalUUID(0x2A5A),
    alert_category_id: canonicalUUID(0x2A43),
    alert_category_id_bit_mask: canonicalUUID(0x2A42),
    alert_level: canonicalUUID(0x2A06),
    alert_notification_control_point: canonicalUUID(0x2A44),
    alert_status: canonicalUUID(0x2A3F),
    altitude: canonicalUUID(0x2AB3),
    anaerobic_heart_rate_lower_limit: canonicalUUID(0x2A81),
    anaerobic_heart_rate_upper_limit: canonicalUUID(0x2A82),
    anaerobic_threshold: canonicalUUID(0x2A83),
    analog: canonicalUUID(0x2A58),
    apparent_wind_direction: canonicalUUID(0x2A73),
    apparent_wind_speed: canonicalUUID(0x2A72),
    'gap.appearance': canonicalUUID(0x2A01),
    barometric_pressure_trend: canonicalUUID(0x2AA3),
    battery_level: canonicalUUID(0x2A19),
    blood_pressure_feature: canonicalUUID(0x2A49),
    blood_pressure_measurement: canonicalUUID(0x2A35),
    body_composition_feature: canonicalUUID(0x2A9B),
    body_composition_measurement: canonicalUUID(0x2A9C),
    body_sensor_location: canonicalUUID(0x2A38),
    bond_management_control_point: canonicalUUID(0x2AA4),
    bond_management_feature: canonicalUUID(0x2AA5),
    boot_keyboard_input_report: canonicalUUID(0x2A22),
    boot_keyboard_output_report: canonicalUUID(0x2A32),
    boot_mouse_input_report: canonicalUUID(0x2A33),
    'gap.central_address_resolution_support': canonicalUUID(0x2AA6),
    cgm_feature: canonicalUUID(0x2AA8),
    cgm_measurement: canonicalUUID(0x2AA7),
    cgm_session_run_time: canonicalUUID(0x2AAB),
    cgm_session_start_time: canonicalUUID(0x2AAA),
    cgm_specific_ops_control_point: canonicalUUID(0x2AAC),
    cgm_status: canonicalUUID(0x2AA9),
    csc_feature: canonicalUUID(0x2A5C),
    csc_measurement: canonicalUUID(0x2A5B),
    current_time: canonicalUUID(0x2A2B),
    cycling_power_control_point: canonicalUUID(0x2A66),
    cycling_power_feature: canonicalUUID(0x2A65),
    cycling_power_measurement: canonicalUUID(0x2A63),
    cycling_power_vector: canonicalUUID(0x2A64),
    database_change_increment: canonicalUUID(0x2A99),
    date_of_birth: canonicalUUID(0x2A85),
    date_of_threshold_assessment: canonicalUUID(0x2A86),
    date_time: canonicalUUID(0x2A08),
    day_date_time: canonicalUUID(0x2A0A),
    day_of_week: canonicalUUID(0x2A09),
    descriptor_value_changed: canonicalUUID(0x2A7D),
    'gap.device_name': canonicalUUID(0x2A00),
    dew_point: canonicalUUID(0x2A7B),
    digital: canonicalUUID(0x2A56),
    dst_offset: canonicalUUID(0x2A0D),
    elevation: canonicalUUID(0x2A6C),
    email_address: canonicalUUID(0x2A87),
    exact_time_256: canonicalUUID(0x2A0C),
    fat_burn_heart_rate_lower_limit: canonicalUUID(0x2A88),
    fat_burn_heart_rate_upper_limit: canonicalUUID(0x2A89),
    firmware_revision_string: canonicalUUID(0x2A26),
    first_name: canonicalUUID(0x2A8A),
    five_zone_heart_rate_limits: canonicalUUID(0x2A8B),
    floor_number: canonicalUUID(0x2AB2),
    gender: canonicalUUID(0x2A8C),
    glucose_feature: canonicalUUID(0x2A51),
    glucose_measurement: canonicalUUID(0x2A18),
    glucose_measurement_context: canonicalUUID(0x2A34),
    gust_factor: canonicalUUID(0x2A74),
    hardware_revision_string: canonicalUUID(0x2A27),
    heart_rate_control_point: canonicalUUID(0x2A39),
    heart_rate_max: canonicalUUID(0x2A8D),
    heart_rate_measurement: canonicalUUID(0x2A37),
    heat_index: canonicalUUID(0x2A7A),
    height: canonicalUUID(0x2A8E),
    hid_control_point: canonicalUUID(0x2A4C),
    hid_information: canonicalUUID(0x2A4A),
    hip_circumference: canonicalUUID(0x2A8F),
    humidity: canonicalUUID(0x2A6F),
    'ieee_11073-20601_regulatory_certification_data_list': canonicalUUID(0x2A2A),
    indoor_positioning_configuration: canonicalUUID(0x2AAD),
    intermediate_blood_pressure: canonicalUUID(0x2A36),
    intermediate_temperature: canonicalUUID(0x2A1E),
    irradiance: canonicalUUID(0x2A77),
    language: canonicalUUID(0x2AA2),
    last_name: canonicalUUID(0x2A90),
    latitude: canonicalUUID(0x2AAE),
    ln_control_point: canonicalUUID(0x2A6B),
    ln_feature: canonicalUUID(0x2A6A),
    'local_east_coordinate.xml': canonicalUUID(0x2AB1),
    local_north_coordinate: canonicalUUID(0x2AB0),
    local_time_information: canonicalUUID(0x2A0F),
    location_and_speed: canonicalUUID(0x2A67),
    location_name: canonicalUUID(0x2AB5),
    longitude: canonicalUUID(0x2AAF),
    magnetic_declination: canonicalUUID(0x2A2C),
    magnetic_flux_density_2D: canonicalUUID(0x2AA0),
    magnetic_flux_density_3D: canonicalUUID(0x2AA1),
    manufacturer_name_string: canonicalUUID(0x2A29),
    maximum_recommended_heart_rate: canonicalUUID(0x2A91),
    measurement_interval: canonicalUUID(0x2A21),
    model_number_string: canonicalUUID(0x2A24),
    navigation: canonicalUUID(0x2A68),
    new_alert: canonicalUUID(0x2A46),
    'gap.peripheral_preferred_connection_parameters': canonicalUUID(0x2A04),
    'gap.peripheral_privacy_flag': canonicalUUID(0x2A02),
    plx_continuous_measurement: canonicalUUID(0x2A5F),
    plx_features: canonicalUUID(0x2A60),
    plx_spot_check_measurement: canonicalUUID(0x2A5E),
    pnp_id: canonicalUUID(0x2A50),
    pollen_concentration: canonicalUUID(0x2A75),
    position_quality: canonicalUUID(0x2A69),
    pressure: canonicalUUID(0x2A6D),
    protocol_mode: canonicalUUID(0x2A4E),
    rainfall: canonicalUUID(0x2A78),
    'gap.reconnection_address': canonicalUUID(0x2A03),
    record_access_control_point: canonicalUUID(0x2A52),
    reference_time_information: canonicalUUID(0x2A14),
    report: canonicalUUID(0x2A4D),
    report_map: canonicalUUID(0x2A4B),
    resting_heart_rate: canonicalUUID(0x2A92),
    ringer_control_point: canonicalUUID(0x2A40),
    ringer_setting: canonicalUUID(0x2A41),
    rsc_feature: canonicalUUID(0x2A54),
    rsc_measurement: canonicalUUID(0x2A53),
    sc_control_point: canonicalUUID(0x2A55),
    scan_interval_window: canonicalUUID(0x2A4F),
    scan_refresh: canonicalUUID(0x2A31),
    sensor_location: canonicalUUID(0x2A5D),
    serial_number_string: canonicalUUID(0x2A25),
    'gatt.service_changed': canonicalUUID(0x2A05),
    software_revision_string: canonicalUUID(0x2A28),
    sport_type_for_aerobic_and_anaerobic_thresholds: canonicalUUID(0x2A93),
    supported_new_alert_category: canonicalUUID(0x2A47),
    supported_unread_alert_category: canonicalUUID(0x2A48),
    system_id: canonicalUUID(0x2A23),
    temperature: canonicalUUID(0x2A6E),
    temperature_measurement: canonicalUUID(0x2A1C),
    temperature_type: canonicalUUID(0x2A1D),
    three_zone_heart_rate_limits: canonicalUUID(0x2A94),
    time_accuracy: canonicalUUID(0x2A12),
    time_source: canonicalUUID(0x2A13),
    time_update_control_point: canonicalUUID(0x2A16),
    time_update_state: canonicalUUID(0x2A17),
    time_with_dst: canonicalUUID(0x2A11),
    time_zone: canonicalUUID(0x2A0E),
    true_wind_direction: canonicalUUID(0x2A71),
    true_wind_speed: canonicalUUID(0x2A70),
    two_zone_heart_rate_limit: canonicalUUID(0x2A95),
    tx_power_level: canonicalUUID(0x2A07),
    uncertainty: canonicalUUID(0x2AB4),
    unread_alert_status: canonicalUUID(0x2A45),
    user_control_point: canonicalUUID(0x2A9F),
    user_index: canonicalUUID(0x2A9A),
    uv_index: canonicalUUID(0x2A76),
    vo2_max: canonicalUUID(0x2A96),
    waist_circumference: canonicalUUID(0x2A97),
    weight: canonicalUUID(0x2A98),
    weight_measurement: canonicalUUID(0x2A9D),
    weight_scale_feature: canonicalUUID(0x2A9E),
    wind_chill: canonicalUUID(0x2A79)
  };

  BluetoothUUID.descriptor = {
    'gatt.characteristic_extended_properties': canonicalUUID(0x2900),
    'gatt.characteristic_user_description': canonicalUUID(0x2901),
    'gatt.client_characteristic_configuration': canonicalUUID(0x2902),
    'gatt.server_characteristic_configuration': canonicalUUID(0x2903),
    'gatt.characteristic_presentation_format': canonicalUUID(0x2904),
    'gatt.characteristic_aggregate_format': canonicalUUID(0x2905),
    valid_range: canonicalUUID(0x2906),
    external_report_reference: canonicalUUID(0x2907),
    report_reference: canonicalUUID(0x2908),
    value_trigger_setting: canonicalUUID(0x290A),
    es_configuration: canonicalUUID(0x290B),
    es_measurement: canonicalUUID(0x290C),
    es_trigger_setting: canonicalUUID(0x290D)
  };

  function resolveUUIDName(tableName) {
    let table = BluetoothUUID[tableName];
    return function (name) {
      if (typeof name === 'number') {
        return canonicalUUID(name);
      }
      if (uuidRegex.test(name)) {
        //note native IOS bridges converts to uppercase since IOS seems to demand this.
        return name.toLowerCase();
      }
      if (table.hasOwnProperty(name)) {
        return table[name];
      }
      if (shortUUIDRegex.test(name)) {
        // this is not in the spec,
        // https://webbluetoothcg.github.io/web-bluetooth/#resolveuuidname
        // but iOS sends us short UUIDs and so we need to handle it.
        return canonicalUUID(parseInt(name, 16));
      }
      throw new TypeError(`${name} is not a known ${tableName} name.`);
    };
  }

  BluetoothUUID.getService = resolveUUIDName('service');
  BluetoothUUID.getCharacteristic = resolveUUIDName('characteristic');
  BluetoothUUID.getDescriptor = resolveUUIDName('descriptor');
  window.BluetoothUUID = BluetoothUUID;
  nslog('BluetoothUUID imported');
})();
