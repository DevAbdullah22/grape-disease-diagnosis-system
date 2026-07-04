// مكون يتيح رفع صورة غلاف للمحتوى، ويعرض معاينة فور اختيار الصورة أو رسالة دعوة للرفع.
import type { ChangeEvent, RefObject } from 'react';

import { Image, Upload, X } from 'lucide-react';

import { Button } from '../../../components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../../../components/ui/card';

interface ImageUploaderProps {
  imagePreview: string;
  fileInputRef: RefObject<HTMLInputElement | null>;
  onImageUpload: (event: ChangeEvent<HTMLInputElement>) => void;
  onRemoveImage: () => void;
}

export function ImageUploader({
  imagePreview,
  fileInputRef,
  onImageUpload,
  onRemoveImage
}: ImageUploaderProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Image className="h-5 w-5 text-green-600" />
          رفع الصورة <span className="text-red-600 text-xs">(هذا الحقل مطلوب)</span>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="text-sm text-gray-600 mb-4">
          الصورة ستظهر كغلاف للمقال
        </div>

        {/* إذا لم توجد معاينة، يتم فتح متصفح الملفات عند النقر */}
        {!imagePreview ? (
          <div
            onClick={() => fileInputRef.current?.click()}
            className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center cursor-pointer hover:border-green-500 hover:bg-green-50 transition-colors"
          >
            <Upload className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-600 mb-2">اضغط لرفع صورة</p>
            <p className="text-sm text-gray-500">PNG, JPG أو GIF (حد أقصى 5MB)</p>
          </div>
        ) : (
          // عرض المعاينة مع زر لحذف الصورة المختارة
          <div className="relative">
            <img
              src={imagePreview}
              alt="معاينة الصورة"
              className="w-full h-64 object-cover rounded-lg"
            />
            <Button
              onClick={onRemoveImage}
              variant="destructive"
              size="sm"
              className="absolute top-2 right-2"
            >
              <X className="h-4 w-4" />
            </Button>
          </div>
        )}

        {/* العنصر الفعلي لتحميل الملف مخفي، ويتم التحكم به عبر المرجع */}
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          onChange={onImageUpload}
          className="hidden"
        />
      </CardContent>
    </Card>
  );
}
