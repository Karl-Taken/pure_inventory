
import { useState, useLayoutEffect } from 'react';

export const useScale = () => {
    useLayoutEffect(() => {
        const handleResize = () => {
            const { innerWidth, innerHeight } = window;
            const widthScale = innerWidth / 1920;
            const heightScale = innerHeight / 1080;
            const scale = Math.min(widthScale, heightScale);

            document.documentElement.style.fontSize = `${16 * scale}px`;
        };

        handleResize();

        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);
};
