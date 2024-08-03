<style>
#comments-section {
  background-color: #1c1c1c;
  color: #ffffff;
  padding: 20px;
  border-radius: 15px;
  max-width: 700px;
  margin: 20px auto;
  box-shadow: 0 10px 20px rgba(0, 0, 0, 0.5);
  font-family: 'Helvetica Neue', Arial, sans-serif;
}

#comments-section h2 {
  color: #00bfff;
  text-align: center;
  margin-bottom: 25px;
  font-size: 24px;
  border-bottom: 2px solid #00bfff;
  padding-bottom: 10px;
}

#comment-form {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

#comment-input {
  padding: 15px;
  border: none;
  border-radius: 10px;
  background-color: #2e2e2e;
  color: #ffffff;
  font-size: 16px;
  resize: none;
  height: 120px;
  box-shadow: inset 0 4px 8px rgba(0, 0, 0, 0.6);
  transition: all 0.3s ease;
}

#comment-input:focus {
  outline: none;
  background-color: #3e3e3e;
}

#comment-form button {
  padding: 15px;
  border: none;
  border-radius: 10px;
  background-color: #00bfff;
  color: #ffffff;
  font-size: 18px;
  cursor: pointer;
  transition: background-color 0.3s ease, transform 0.3s ease;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.5);
}

#comment-form button:hover {
  background-color: #009acd;
  transform: translateY(-2px);
}

#comments-list {
  margin-top: 30px;
  max-height: 350px;
  overflow-y: auto;
}

.comment {
  background-color: #292b2c;
  padding: 20px;
  border-radius: 10px;
  margin-bottom: 20px;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.5);
  transition: transform 0.3s ease;
}

.comment:hover {
  transform: translateY(-5px);
}

.comment p {
  margin: 0;
}

.comment-time {
  font-size: 0.85em;
  color: #b0b3b8;
  margin-top: 15px;
  text-align: right;
}

 </style>

<html>
<div id="comments-section">
  <h2>Comentarios</h2>
  <form id="comment-form">
    <textarea id="comment-input" placeholder="Escribe tu comentario aquí..." required></textarea>
    <button type="submit">Enviar</button>
  </form>
  <div id="comments-list">
    <!-- Los comentarios se mostrarán aquí -->
  </div>
</div>

 </html>

<script>

  document.addEventListener('DOMContentLoaded', (event) => {
    loadComments();
  });

  document.getElementById('comment-form').addEventListener('submit', function(e) {
    e.preventDefault();

    const commentInput = document.getElementById('comment-input');
    const commentText = commentInput.value;
    const commentTime = new Date().toLocaleString();
    
    const comment = {
      text: commentText,
      time: commentTime
    };

    saveComment(comment);
    displayComment(comment);
    commentInput.value = '';
  });

  function saveComment(comment) {
    let comments = JSON.parse(localStorage.getItem('comments')) || [];
    comments.push(comment);
    localStorage.setItem('comments', JSON.stringify(comments));
  }

  function loadComments() {
    let comments = JSON.parse(localStorage.getItem('comments')) || [];
    comments.forEach(comment => {
      displayComment(comment);
    });
  }

  function displayComment(comment) {
    const commentElement = document.createElement('div');
    commentElement.className = 'comment';
    
    const commentContent = document.createElement('p');
    commentContent.textContent = comment.text;
    
    const commentTimeElement = document.createElement('p');
    commentTimeElement.className = 'comment-time';
    commentTimeElement.textContent = `Enviado el: ${comment.time}`;
    
    commentElement.appendChild(commentContent);
    commentElement.appendChild(commentTimeElement);
    
    document.getElementById('comments-list').appendChild(commentElement);
  }

</script>
