<?php
/**
 * Plugin Name: Vireoka Sync Monitor
 * Description: Admin dashboard for Vireoka two-way sync (status + conflicts).
 * Version: 1.0.0
 * Author: Vireoka
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Get sync JSON helper.
 */
function vireoka_sync_get_json( $filename ) {
    $base_dir = trailingslashit( ABSPATH ) . '_sync_status';
    $path     = trailingslashit( $base_dir ) . $filename;

    if ( ! file_exists( $path ) ) {
        return null;
    }

    $raw  = file_get_contents( $path );
    $data = json_decode( $raw, true );

    if ( json_last_error() !== JSON_ERROR_NONE ) {
        return null;
    }

    return $data;
}

/**
 * Add admin menu.
 */
function vireoka_sync_monitor_menu() {
    add_menu_page(
        'Vireoka Sync Dashboard',
        'Vireoka Sync',
        'manage_options',
        'vireoka-sync-dashboard',
        'vireoka_sync_monitor_page',
        'dashicons-update-alt',
        81
    );
}
add_action( 'admin_menu', 'vireoka_sync_monitor_menu' );

/**
 * Render dashboard page.
 */
function vireoka_sync_monitor_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        return;
    }

    $status    = vireoka_sync_get_json( 'status.json' );
    $conflicts = vireoka_sync_get_json( 'conflicts.json' );

    $last_ts   = isset( $status['timestamp'] ) ? esc_html( $status['timestamp'] ) : 'Unknown';
    $mode      = isset( $status['mode'] ) ? esc_html( $status['mode'] ) : 'N/A';
    $message   = isset( $status['message'] ) ? esc_html( $status['message'] ) : 'No recent status.';
    $conf_list = array();

    if ( isset( $conflicts['conflicts'] ) && is_array( $conflicts['conflicts'] ) ) {
        $conf_list = $conflicts['conflicts'];
    }

    ?>
    <div class="wrap vireoka-sync-wrap">
        <h1>Vireoka Sync Dashboard</h1>
        <p>Live view of the Vireoka two-way sync system (plugins, themes, uploads).</p>

        <style>
            .vireoka-sync-cards {
                display: flex;
                flex-wrap: wrap;
                gap: 16px;
                margin: 20px 0;
            }
            .vireoka-card {
                background: #fff;
                border-radius: 8px;
                padding: 16px 18px;
                box-shadow: 0 2px 6px rgba(0,0,0,0.06);
                border: 1px solid #e5e7eb;
                flex: 1 1 260px;
            }
            .vireoka-card h2 {
                margin: 0 0 8px;
                font-size: 1.1rem;
            }
            .vireoka-badge {
                display: inline-block;
                padding: 2px 8px;
                border-radius: 999px;
                font-size: 11px;
                font-weight: 600;
                text-transform: uppercase;
                letter-spacing: 0.06em;
            }
            .vireoka-badge-ok {
                background: #e0f7e9;
                color: #166534;
            }
            .vireoka-badge-warn {
                background: #fef3c7;
                color: #92400e;
            }
            .vireoka-badge-err {
                background: #fee2e2;
                color: #b91c1c;
            }
            .vireoka-conf-table {
                width: 100%;
                border-collapse: collapse;
                margin-top: 10px;
            }
            .vireoka-conf-table th,
            .vireoka-conf-table td {
                border: 1px solid #e5e7eb;
                padding: 6px 8px;
                font-size: 13px;
            }
            .vireoka-conf-table th {
                background: #f9fafb;
                text-align: left;
            }
            .vireoka-conf-empty {
                margin-top: 8px;
                font-size: 13px;
                color: #6b7280;
            }
            .vireoka-meta {
                margin-top: 10px;
                font-size: 12px;
                color: #6b7280;
            }
            .vireoka-sync-footer {
                margin-top: 20px;
                font-size: 12px;
                color: #6b7280;
            }
        </style>

        <div class="vireoka-sync-cards">
            <div class="vireoka-card">
                <h2>Last Sync</h2>
                <p><strong>Timestamp:</strong> <?php echo $last_ts; ?></p>
                <p><strong>Mode:</strong> <?php echo $mode; ?></p>
                <p><strong>Message:</strong> <?php echo $message; ?></p>
                <?php
                $badge_class = 'vireoka-badge-ok';
                $badge_label = 'Healthy';
                if ( strpos( strtolower( $message ), 'conflict' ) !== false ) {
                    $badge_class = 'vireoka-badge-warn';
                    $badge_label = 'Conflicts';
                }
                ?>
                <span class="vireoka-badge <?php echo esc_attr( $badge_class ); ?>">
                    <?php echo esc_html( $badge_label ); ?>
                </span>
                <div class="vireoka-meta">
                    Source: <code>_sync_status/status.json</code>
                </div>
            </div>

            <div class="vireoka-card">
                <h2>Conflicts</h2>
                <?php if ( empty( $conf_list ) ) : ?>
                    <div class="vireoka-conf-empty">No conflicts recorded in the last run.</div>
                <?php else : ?>
                    <table class="vireoka-conf-table">
                        <thead>
                            <tr>
                                <th>File</th>
                                <th>Local mtime</th>
                                <th>Remote mtime</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ( $conf_list as $conf ) : ?>
                            <tr>
                                <td><code><?php echo esc_html( $conf['file'] ?? '' ); ?></code></td>
                                <td><?php echo esc_html( $conf['local'] ?? '' ); ?></td>
                                <td><?php echo esc_html( $conf['remote'] ?? '' ); ?></td>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                    <div class="vireoka-meta">
                        Source: <code>_sync_status/conflicts.json</code>
                    </div>
                <?php endif; ?>
            </div>
        </div>

        <div class="vireoka-sync-footer">
            Vireoka Sync Monitor · Reads JSON generated by the vsync toolchain (plugins/themes/uploads).
        </div>
    </div>
    <?php
}
