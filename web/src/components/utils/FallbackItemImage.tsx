import React, { useEffect, useState } from 'react';

type FallbackItemImageProps = Omit<React.ImgHTMLAttributes<HTMLImageElement>, 'src'> & {
  src?: string;
};

const FallbackItemImage: React.FC<FallbackItemImageProps> = ({ src, alt = '', className, onError, ...props }) => {
  const [failed, setFailed] = useState(!src || src === 'none');

  useEffect(() => {
    setFailed(!src || src === 'none');
  }, [src]);

  if (failed) {
    return (
      <div className={`item-image-fallback${className ? ` ${className}` : ''}`} aria-label={alt}>
        ?
      </div>
    );
  }

  return (
    <img
      {...props}
      src={src}
      alt={alt}
      className={className}
      onError={(event) => {
        setFailed(true);
        onError?.(event);
      }}
    />
  );
};

export default FallbackItemImage;
