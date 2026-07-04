// مكون اختيار الفئة يسمح بالاختيار من الفئات الموجودة أو إنشاء فئة جديدة في نفس الواجهة.
import type { Dispatch, SetStateAction } from 'react';

import { Plus } from 'lucide-react';

import { Button } from '../../../components/ui/button';
import { Input } from '../../../components/ui/input';
import { Label } from '../../../components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../../../components/ui/select';
import type { Category, FormDataState } from '../types/library.types';

interface CategorySelectorProps {
  formData: FormDataState;
  updateForm: (updates: Partial<FormDataState>) => void;
  errors: { [key: string]: string };
  setErrors: Dispatch<SetStateAction<{ [key: string]: string }>>;
  categoriesState: Category[];
  showNewCategory: boolean;
  setShowNewCategory: Dispatch<SetStateAction<boolean>>;
  isCreatingCategory: boolean;
  newCategoryError: string;
  setNewCategoryError: Dispatch<SetStateAction<string>>;
  onCreateCategoryNow: () => void | Promise<void>;
}

export function CategorySelector({
  formData,
  updateForm,
  errors,
  setErrors,
  categoriesState,
  showNewCategory,
  setShowNewCategory,
  isCreatingCategory,
  newCategoryError,
  setNewCategoryError,
  onCreateCategoryNow
}: CategorySelectorProps) {
  return (
    <div className="space-y-4">
      <Label className="text-lg font-medium">
        الفئة <span className="text-red-600 text-xs">(هذا الحقل مطلوب)</span>
      </Label>
      <div className="space-y-3">
        <div className="flex items-start gap-3">
          {/* قائمة الاختيار الرئيسية للفئات الموجودة */}
          <Select
            dir="rtl"
            value={formData.category}
            onValueChange={(value: string) => {
              updateForm({ category: value, newCategory: '' });
              setShowNewCategory(false);
              if (errors.category) setErrors(prev => ({ ...prev, category: '' }));
            }}
            disabled={showNewCategory}
          >
            <SelectTrigger
              className={`flex-1 bg-gray-50 text-right *:data-[slot=select-value]:justify-end ${errors.category ? 'border-red-500' : ''}`}
            >
              <SelectValue placeholder="اختر فئة موجودة" />
            </SelectTrigger>
            <SelectContent className="bg-gray-50 text-right">
              {categoriesState.map(c => (
                <SelectItem key={c.id} value={c.name} className="text-right">
                  {c.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          {/* زر للتبديل إلى وضع إنشاء فئة جديدة */}
          <Button
            variant={showNewCategory ? 'default' : 'outline'}
            size="default"
            onClick={() => {
              setShowNewCategory(!showNewCategory);
              if (!showNewCategory) {
                updateForm({ category: '', newCategory: '' });
                setErrors(prev => ({ ...prev, category: '' }));
              }
            }}
            className="px-4"
          >
            <Plus className="h-4 w-4 ml-2" />
            {showNewCategory ? 'إلغاء' : 'فئة جديدة'}
          </Button>
        </div>

        {errors.category && !showNewCategory && (
          <p className="text-red-600 text-sm text-right">{errors.category}</p>
        )}

        {/* واجهة إنشاء فئة جديدة وتأكيدها */}
        {showNewCategory && (
          <div className="p-4 bg-blue-50 rounded-lg border-2 border-dashed border-blue-200">
            <Label htmlFor="newCategory" className="text-blue-700 font-medium">اسم الفئة الجديدة</Label>
            <Input
              id="newCategory"
              placeholder="أدخل اسم الفئة الجديدة (مثل: الأسمدة العضوية)"
              value={formData.newCategory}
              onChange={(e) => {
                updateForm({ newCategory: e.target.value, category: '' });
                setNewCategoryError('');
              }}
              className="text-right mt-2 border-blue-300 focus:border-blue-500"
              disabled={isCreatingCategory}
            />
            <div className="flex gap-2 mt-4">
              <Button
                variant="default"
                size="sm"
                onClick={onCreateCategoryNow}
                disabled={isCreatingCategory || !formData.newCategory.trim()}
                className="flex items-center gap-2"
              >
                {isCreatingCategory && (
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                )}
                <Plus className="h-4 w-4" />
                إنشاء الآن
              </Button>
            </div>
            <p className="text-sm text-blue-600 mt-2">
              سيتم إنشاء الفئة وإضافتها للقائمة فورًا
            </p>
            {newCategoryError && <p className="text-red-600 text-sm mt-2">{newCategoryError}</p>}
          </div>
        )}
      </div>
    </div>
  );
}
