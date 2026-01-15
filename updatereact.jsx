import React from 'react';

const WelcomePage = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-900 via-purple-800 to-pink-700 flex flex-col items-center justify-center p-4 text-white">
      <div className="text-center animate-fade-in">
        <h1 className="text-6xl md:text-8xl font-bold mb-4 bg-clip-text text-transparent bg-gradient-to-r from-cyan-300 to-pink-300 drop-shadow-lg">
          Привет
        </h1>
        
        <div className="flex items-center justify-center mt-6 group">
          <span className="text-3xl mr-3 animate-bounce">📱</span>
          <p className="text-xl md:text-2xl font-medium bg-white/10 backdrop-blur-sm px-4 py-2 rounded-full border border-white/20 hover:border-cyan-300 transition-all duration-300">
            Контакт для связи Telegram: 
            <a 
              href="https://t.me/mihail" 
              target="_blank" 
              rel="noopener noreferrer"
              className="ml-1 font-bold text-cyan-300 hover:text-cyan-100 transition-colors underline decoration-dotted"
            >
              @mihail
            </a>
          </p>
        </div>
      </div>
      
      <style jsx>{`
        @import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@700;800&family=Open+Sans:wght@400;600&display=swap');
        
        .animate-fade-in {
          animation: fadeIn 1.2s ease-out forwards;
        }
        
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }
        
        h1 {
          font-family: 'Montserrat', sans-serif;
          letter-spacing: -2px;
          text-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        }
        
        p {
          font-family: 'Open Sans', sans-serif;
        }
      `}</style>
    </div>
  );
};

export default WelcomePage;
