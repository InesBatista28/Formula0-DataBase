using System;
using System.ComponentModel;
using System.Data;
using System.Windows;
using System.Windows.Controls;

namespace ProjetoFBD
{
    public partial class CircuitsGridControl : System.Windows.Controls.UserControl, INotifyPropertyChanged
    {
        public CircuitsGridControl()
        {
            InitializeComponent();
            DataContext = this;
        }

        public event PropertyChangedEventHandler? PropertyChanged;
        private void OnPropertyChanged(string name) => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));

        public static readonly DependencyProperty ItemsSourceProperty = DependencyProperty.Register(
            nameof(ItemsSource), typeof(object), typeof(CircuitsGridControl), new PropertyMetadata(null));

        public object? ItemsSource
        {
            get => GetValue(ItemsSourceProperty);
            set { SetValue(ItemsSourceProperty, value); OnPropertyChanged(nameof(ItemsSource)); }
        }

        public event EventHandler<string>? MapRequested;

        private void MapButton_Click(object sender, RoutedEventArgs e)
        {
            if (Grid.CurrentItem is DataRowView row)
            {
                string name = row.Row["Nome"]?.ToString() ?? string.Empty;
                if (!string.IsNullOrWhiteSpace(name))
                {
                    MapRequested?.Invoke(this, name);
                }
            }
        }
    }
}
