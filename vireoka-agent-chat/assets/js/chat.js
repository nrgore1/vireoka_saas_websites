(function ($) {
  $(function () {
    var $launcher = $('#vk-chat-launcher');
    var $window = $('#vk-chat-window');
    var $close = $('#vk-chat-close');
    var $messages = $('#vk-chat-messages');
    var $input = $('#vk-chat-input');
    var $send = $('#vk-chat-send');
if (!$launcher.length) return;
function addMessage(text, type) {
      var cls = type === 'user' ? 'vk-chat-msg-user' : 'vk-chat-msg-agent';
      var $msg = $('<div/>')
        .addClass('vk-chat-msg ' + cls)
        .text(text);
      $messages.append($msg);
      $messages.scrollTop($messages[0].scrollHeight);
    }
$launcher.on('click', function () {
      $window.show();
      $launcher.hide();
      if (!$messages.children().length) {
        addMessage('Hi, I\'m the Vireoka agent. Ask me about this site.', 'agent');
      }
    });
$close.on('click', function () {
      $window.hide();
      $launcher.show();
    });
function sendMessage() {
      var text = $input.val().trim();
      if (!text) return;
      addMessage(text, 'user');
      $input.val('');
$.ajax({
        url: VireokaAgentChat.restUrl,
        method: 'POST',
        contentType: 'application/json',
        headers: {
          'X-WP-Nonce': VireokaAgentChat.nonce
        },
        data: JSON.stringify({ message: text }),
        success: function (res) {
          if (res && res.ok && res.message) {
            addMessage(res.message, 'agent');
          } else {
            addMessage('Sorry, I had trouble answering that.', 'agent');
          }
        },
        error: function (xhr) {
          addMessage('The agent API seems unavailable. Please try again later.', 'agent');
        }
      });
    }
$send.on('click', sendMessage);
    $input.on('keydown', function (e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
      }
    });
  });
})(jQuery);
