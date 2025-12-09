<?php
/**
 * Plugin Name: Vireoka Agent Chat
 * Description: Floating chat widget that connects to the Vireoka agent API via a WordPress REST proxy.
 * Version: 1.0.0
 * Author: Vireoka
 */
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}
define( 'VIREOKA_AGENT_CHAT_URL', plugin_dir_url( __FILE__ ) );
define( 'VIREOKA_AGENT_CHAT_PATH', plugin_dir_path( __FILE__ ) );
/**
 * Enqueue front-end assets.
 */
add_action( 'wp_enqueue_scripts', function () {
    wp_enqueue_style(
        'vireoka-agent-chat',
        VIREOKA_AGENT_CHAT_URL . 'assets/css/chat.css',
        array(),
        '1.0.0'
    );
wp_enqueue_script(
        'vireoka-agent-chat',
        VIREOKA_AGENT_CHAT_URL . 'assets/js/chat.js',
        array( 'jquery' ),
        '1.0.0',
        true
    );
wp_localize_script(
        'vireoka-agent-chat',
        'VireokaAgentChat',
        array(
            'restUrl' => esc_url_raw( rest_url( 'vireoka/v1/chat' ) ),
            'nonce'   => wp_create_nonce( 'wp_rest' ),
        )
    );
} );
/**
 * Shortcode: [vireoka_agent_chat]
 */
add_shortcode( 'vireoka_agent_chat', function () {
    ob_start(); ?>
    <div class="vk-chat-launcher" id="vk-chat-launcher">
        <div class="vk-chat-launcher-label">Ask Vireoka</div>
    </div>
    <div class="vk-chat-window" id="vk-chat-window">
        <div class="vk-chat-header">
            <div class="vk-chat-title">Vireoka Agent</div>
            <button class="vk-chat-close" id="vk-chat-close">&times;</button>
        </div>
        <div class="vk-chat-messages" id="vk-chat-messages"></div>
        <div class="vk-chat-input-row">
            <textarea id="vk-chat-input" placeholder="Ask about this site, product, or docs..."></textarea>
            <button id="vk-chat-send">Send</button>
        </div>
    </div>
    <?php
    return ob_get_clean();
} );
/**
 * Settings: external API URL + key (simple option fields)
 */
function vireoka_agent_chat_register_settings() {
    register_setting( 'vireoka_agent_chat', 'vireoka_agent_chat_api_url' );
    register_setting( 'vireoka_agent_chat', 'vireoka_agent_chat_api_key' );
}
add_action( 'admin_init', 'vireoka_agent_chat_register_settings' );
/**
 * Settings page.
 */
add_action( 'admin_menu', function () {
    add_options_page(
        'Vireoka Agent Chat',
        'Vireoka Agent Chat',
        'manage_options',
        'vireoka-agent-chat',
        'vireoka_agent_chat_render_settings'
    );
} );
function vireoka_agent_chat_render_settings() {
    if ( ! current_user_can( 'manage_options' ) ) {
        return;
    }
?>
    <div class="wrap">
        <h1>Vireoka Agent Chat Settings</h1>
        <form method="post" action="options.php">
            <?php
            settings_fields( 'vireoka_agent_chat' );
            do_settings_sections( 'vireoka_agent_chat' );
            ?>
            <table class="form-table">
                <tr>
                    <th scope="row"><label for="vireoka_agent_chat_api_url">Agent API URL</label></th>
                    <td>
                        <input type="text" id="vireoka_agent_chat_api_url" name="vireoka_agent_chat_api_url"
                               value="<?php echo esc_attr( get_option( 'vireoka_agent_chat_api_url', '' ) ); ?>"
                               class="regular-text" />
                        <p class="description">Example: https://api.vireoka.com/agent-chat</p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="vireoka_agent_chat_api_key">Agent API Key</label></th>
                    <td>
                        <input type="password" id="vireoka_agent_chat_api_key" name="vireoka_agent_chat_api_key"
                               value="<?php echo esc_attr( get_option( 'vireoka_agent_chat_api_key', '' ) ); ?>"
                               class="regular-text" />
                        <p class="description">Stored in the WordPress options table; used server-side only.</p>
                    </td>
                </tr>
            </table>
            <?php submit_button(); ?>
        </form>
    </div>
    <?php
}
/**
 * REST route: /wp-json/vireoka/v1/chat
 * Proxies messages to external agent API.
 */
add_action( 'rest_api_init', function () {
    register_rest_route( 'vireoka/v1', '/chat', array(
        'methods'             => 'POST',
        'permission_callback' => '__return_true', // public chat
        'callback'            => 'vireoka_agent_chat_handler',
    ) );
} );
function vireoka_agent_chat_handler( WP_REST_Request $request ) {
    $params  = $request->get_json_params();
    $message = isset( $params['message'] ) ? sanitize_text_field( $params['message'] ) : '';
if ( empty( $message ) ) {
        return new WP_REST_Response(
            array( 'ok' => false, 'error' => 'Empty message.' ),
            400
        );
    }
$api_url = trim( get_option( 'vireoka_agent_chat_api_url', '' ) );
    $api_key = trim( get_option( 'vireoka_agent_chat_api_key', '' ) );
if ( empty( $api_url ) ) {
        // Fallback: simple rule-based reply if no external API configured
        $fallback = "Vireoka Agent is not fully configured yet. For now, please use the contact form for detailed questions.";
        return array(
            'ok'      => true,
            'message' => $fallback,
        );
    }
$body = wp_json_encode( array(
        'message' => $message,
        'meta'    => array(
            'site_url'   => home_url(),
            'user_agent' => isset( $_SERVER['HTTP_USER_AGENT'] ) ? sanitize_text_field( wp_unslash( $_SERVER['HTTP_USER_AGENT'] ) ) : '',
        ),
    ) );
$headers = array(
        'Content-Type' => 'application/json',
    );
    if ( ! empty( $api_key ) ) {
        $headers['Authorization'] = 'Bearer ' . $api_key;
    }
$response = wp_remote_post( $api_url, array(
        'headers' => $headers,
        'body'    => $body,
        'timeout' => 20,
    ) );
if ( is_wp_error( $response ) ) {
        return array(
            'ok'      => false,
            'error'   => 'Agent API error',
            'details' => $response->get_error_message(),
        );
    }
$code = wp_remote_retrieve_response_code( $response );
    $raw  = wp_remote_retrieve_body( $response );
    $data = json_decode( $raw, true );
if ( $code >= 400 || ! is_array( $data ) ) {
        return array(
            'ok'      => false,
            'error'   => 'Agent API returned an error or invalid JSON.',
            'details' => $raw,
        );
    }
// Expecting data['reply'] or similar
    $reply = isset( $data['reply'] ) ? $data['reply'] : ( $data['message'] ?? 'Agent replied, but no structured field was found.' );
return array(
        'ok'      => true,
        'message' => $reply,
    );
}
