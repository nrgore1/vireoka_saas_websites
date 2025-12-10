<?php


/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * Localized language
 * * ABSPATH
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'u814009065_yoMLf' );

/** Database username */
define( 'DB_USER', 'u814009065_Yy0d6' );

/** Database password */
define( 'DB_PASSWORD', 'u7tpdK9BUE' );

/** Database hostname */
define( 'DB_HOST', '127.0.0.1' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',          '8-G m72X(:y74>dCrPK,qdTU`BN~}{4$w9$g=M94<Z+BjaNXjWHoEp|(gkCU =EK' );
define( 'SECURE_AUTH_KEY',   'UO_VywBcDP<mRxaiMh%Y,`Tt9:Ra.:88bF8*7(,c%F(5!=ZkyUs( oZ &%!;89>~' );
define( 'LOGGED_IN_KEY',     'iB#vc&t^J@;}kSER-?u`t*S4B= Ci)v?/>D;15PpoMT<=+<Ia72J5?#4sTm:@uRO' );
define( 'NONCE_KEY',         'm()M[{8Dzt)M}+B<E,)Hx8g-3^ryIy{=ju|~_p3yZK-{8-d`kwu:]JWg?bO(w]DV' );
define( 'AUTH_SALT',         '<2[b(%^ZV=#E3L(+QF-#jNxeQpj?;Q)[_x# |R#+8n]z&K8hM=^/<hT+!MOeT0Ed' );
define( 'SECURE_AUTH_SALT',  'Wb(uSJJJWIQ 4n4uSy^VvzJyc9H[PU>{7H2$>cLx[W+b|5r+Els(7ZJ2_5?Ugl*/' );
define( 'LOGGED_IN_SALT',    '=`9;$<=Ln9B($b r>L67]2(Ef=UX~9I/rhJ3:]t[?HQ<ri|82%Uq<B,z{33jdF$~' );
define( 'NONCE_SALT',        ':Nj?1@<JNbi)4e_)l=NayJ1($>hL$0yj`(kx2n,]^~$GbySxTh[jS%j@pA+a}zGu' );
define( 'WP_CACHE_KEY_SALT', '2k6`OQaMy?mrjPM$535!z$y:<n@K,;!M!0H,VqetZkI(!G{$2HSm&>@1e(r?{(0Z' );


/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';


/* Add any custom values between this line and the "stop editing" line. */



/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
if ( ! defined( 'WP_DEBUG' ) ) {
	define( 'WP_DEBUG', true );
}

define( 'FS_METHOD', 'direct' );
define( 'COOKIEHASH', 'd7a5a57031644876fe429f38d73c7a5e' );
define( 'WP_AUTO_UPDATE_CORE', 'minor' );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
