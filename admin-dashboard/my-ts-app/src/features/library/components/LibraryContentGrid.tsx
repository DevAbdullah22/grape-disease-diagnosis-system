// هذا المكون يعرض شبكة عناصر المحتوى في صفحة الإدارة، ويحتوي على حالات التحميل، الحالة الفارغة، وأزرار الإجراءات.
import { Card, CardContent } from '../../../components/ui/card';
import { Badge } from '../../../components/ui/badge';
import { Button } from '../../../components/ui/button';
import { Calendar, Link, Eye, Edit, Trash2 } from 'lucide-react';
import { getCategoryColor } from '../utils/categoryUtils';
import type { ContentItem } from '../types/library.types';

interface LibraryContentGridProps {
  isLoading: boolean;
  contents: ContentItem[];
  onView: (content: ContentItem) => void;
  onEdit: (content: ContentItem) => void;
  onDeleteRequest: (content: ContentItem) => void;
  isDeletingId: string | null;
}

export function LibraryContentGrid({
  isLoading,
  contents,
  onView,
  onEdit,
  onDeleteRequest,
  isDeletingId,
}: LibraryContentGridProps) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6 items-stretch">
      {isLoading ? (
        // عرض مؤشر تحميل أثناء جلب المحتوى من الخادم
        <div className="col-span-full flex justify-center py-12">
          <div className="text-center space-y-3">
            <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-green-600 mx-auto"></div>
            <p className="text-sm md:text-base text-gray-600">
              جارٍ جلب العناصر...
            </p>
          </div>
        </div>
      ) : contents.length === 0 ? (
        // حالة عدم وجود محتويات بعد انتهاء التحميل
        <div className="col-span-full text-center py-12 text-gray-500 text-sm md:text-base">
          لا توجد محتويات متاحة
        </div>
      ) : (
        // عرض كل عنصر في بطاقة منفصلة
        contents.map((content) => (
          <Card
            key={content.id}
            className="h-full flex flex-col rounded-xl overflow-hidden shadow-md hover:shadow-lg transition"
          >
            {/* جزء الصورة والفئة */}
            <div className="relative">
              {content.image ? (
                <img
                  src={content.image}
                  alt={content.title}
                  className="w-full h-44 md:h-48 object-cover"
                />
              ) : (
                <div className="w-full h-44 md:h-48 bg-gray-200 flex items-center justify-center text-gray-400 text-sm">
                  لا توجد صورة
                </div>
              )}

              <div className="absolute top-3 right-3">
                <Badge className={`${getCategoryColor(content.category)} text-xs md:text-sm`}>
                  {content.category}
                </Badge>
              </div>
            </div>

            {/* محتوى البطاقة والعنوان والوصف المختصر */}
            <CardContent className="flex flex-col flex-1 p-4 md:p-6">
              <h3 className="font-bold text-gray-900 text-lg md:text-xl line-clamp-2 min-h-[3.0rem]">
                {content.title}
              </h3>

              <p className="text-gray-600 text-sm mt-2 line-clamp-3 min-h-[5.5rem]">
                {content.shortDescription || ' '}
              </p>

              {/* بيانات التاريخ وعدد المصادر */}
              <div className="flex items-center justify-between text-xs md:text-sm text-gray-500 mt-3">
                <div className="flex items-center gap-1">
                  <Calendar className="h-4 w-4" />
                  {content.createdAt}
                </div>

                {(content.sources?.length ?? 0) > 0 && (
                  <div className="flex items-center gap-1">
                    <Link className="h-4 w-4" />
                    {content.sources?.length ?? 0}
                  </div>
                )}
              </div>

              {/* أزرار العرض والتحرير والحذف */}
              <div className="flex gap-2 mt-auto pt-4">
                <Button
                  onClick={() => onView(content)}
                  className="flex-1 bg-green-600 hover:bg-green-700 text-white text-sm"
                >
                  <Eye className="h-4 w-4 mr-1" />
                  اقرأ المزيد
                </Button>

                <Button
                  onClick={() => onEdit(content)}
                  variant="outline"
                  size="icon"
                >
                  <Edit className="h-4 w-4" />
                </Button>

                <Button
                  onClick={() => onDeleteRequest(content)}
                  variant="outline"
                  size="icon"
                  className="text-red-600 hover:bg-red-50"
                  disabled={typeof content.id === 'string' ? isDeletingId === content.id : false}
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            </CardContent>
          </Card>
        ))
      )}
    </div>
  );
}
